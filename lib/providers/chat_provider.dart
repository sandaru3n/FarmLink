import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';
import '../models/transport_order_model.dart';
import '../models/delivery_order_model.dart';
import '../services/ai_chat_service.dart';

class ChatProvider with ChangeNotifier {
  final AIChatService _aiChatService = AIChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  List<ChatConversationModel> _conversations = [];
  List<ChatMessageModel> _currentMessages = [];
  String? _currentConversationId;
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;
  Map<String, dynamic>? _transporterContext;

  // Getters
  List<ChatConversationModel> get conversations => _conversations;
  List<ChatMessageModel> get currentMessages => _currentMessages;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;
  Map<String, dynamic>? get transporterContext => _transporterContext;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize chat provider with transporter context
  Future<void> initialize({
    List<TransportOrderModel>? activeOrders,
    List<DeliveryOrderModel>? pendingDeliveries,
    Map<String, dynamic>? context,
  }) async {
    if (currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Set transporter context
      _transporterContext = {
        'activeOrders': activeOrders?.length ?? 0,
        'pendingDeliveries': pendingDeliveries?.length ?? 0,
        'totalEarnings': context?['totalEarnings'] ?? 0,
        'completedDeliveries': context?['completedDeliveries'] ?? 0,
        'name': context?['name'] ?? 'Transporter',
        ...?context,
      };

      // Load user conversations
      await loadConversations();

      // Create default conversation if none exists
      if (_conversations.isEmpty) {
        await createNewConversation();
      } else {
        // Load the most recent conversation
        await loadConversation(_conversations.first.id);
      }
    } catch (e) {
      _setError('Failed to initialize chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user conversations
  Future<void> loadConversations() async {
    if (currentUserId == null) return;

    try {
      _conversations = await _aiChatService.getUserConversations(currentUserId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversations: $e');
    }
  }

  /// Create a new conversation
  Future<String> createNewConversation() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final conversationId = await _aiChatService.createConversation(
        userId: currentUserId!,
        userName: _transporterContext?['name'] ?? 'Transporter',
        userRole: 'transporter',
        context: _transporterContext,
      );

      // Reload conversations
      await loadConversations();
      
      // Load the new conversation
      await loadConversation(conversationId);

      return conversationId;
    } catch (e) {
      _setError('Failed to create conversation: $e');
      rethrow;
    }
  }

  /// Load a specific conversation
  Future<void> loadConversation(String conversationId) async {
    try {
      _currentConversationId = conversationId;
      _currentMessages = await _aiChatService.getConversationMessages(conversationId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversation: $e');
    }
  }

  /// Stream messages for current conversation
  Stream<List<ChatMessageModel>> streamCurrentMessages() {
    if (_currentConversationId == null) {
      return Stream.value([]);
    }
    return _aiChatService.streamConversationMessages(_currentConversationId!);
  }

  /// Send a message to AI
  Future<void> sendMessage(String message) async {
    if (_currentConversationId == null || currentUserId == null) {
      _setError('No active conversation');
      return;
    }

    if (message.trim().isEmpty) return;

    _setSendingMessage(true);
    _clearError();

    try {
      // Get current transporter context
      final activeOrders = _transporterContext?['activeOrdersList'] as List<TransportOrderModel>?;
      final pendingDeliveries = _transporterContext?['pendingDeliveriesList'] as List<DeliveryOrderModel>?;

      await _aiChatService.sendMessageToAI(
        conversationId: _currentConversationId!,
        message: message.trim(),
        userId: currentUserId!,
        userName: _transporterContext?['name'] ?? 'Transporter',
        activeOrders: activeOrders,
        pendingDeliveries: pendingDeliveries,
        transporterContext: _transporterContext,
      );

      // Reload messages
      await loadConversation(_currentConversationId!);
      
      // Reload conversations to update last message
      await loadConversations();
    } catch (e) {
      _setError('Failed to send message: $e');
    } finally {
      _setSendingMessage(false);
    }
  }

  /// Update transporter context
  void updateTransporterContext({
    List<TransportOrderModel>? activeOrders,
    List<DeliveryOrderModel>? pendingDeliveries,
    Map<String, dynamic>? context,
  }) {
    _transporterContext = {
      'activeOrders': activeOrders?.length ?? 0,
      'pendingDeliveries': pendingDeliveries?.length ?? 0,
      'activeOrdersList': activeOrders,
      'pendingDeliveriesList': pendingDeliveries,
      'totalEarnings': context?['totalEarnings'] ?? 0,
      'completedDeliveries': context?['completedDeliveries'] ?? 0,
      'name': context?['name'] ?? 'Transporter',
      ...?context,
    };
    notifyListeners();
  }

  /// Handle AI action
  Future<void> handleAIAction(String actionType, Map<String, dynamic>? actionData) async {
    try {
      final result = await _aiChatService.handleAIAction(actionType, actionData);
      
      if (result['success'] == true) {
        // Clear error
        _clearError();
      } else {
        _setError(result['message'] ?? 'Action failed');
      }
    } catch (e) {
      _setError('Failed to handle action: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _aiChatService.deleteConversation(conversationId);
      
      // If deleting current conversation, switch to another or create new
      if (_currentConversationId == conversationId) {
        _conversations.removeWhere((conv) => conv.id == conversationId);
        
        if (_conversations.isNotEmpty) {
          await loadConversation(_conversations.first.id);
        } else {
          await createNewConversation();
        }
      } else {
        await loadConversations();
      }
    } catch (e) {
      _setError('Failed to delete conversation: $e');
    }
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadConversations();
    if (_currentConversationId != null) {
      await loadConversation(_currentConversationId!);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSendingMessage(bool sending) {
    _isSendingMessage = sending;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
