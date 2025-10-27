import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';
import '../models/transport_order_model.dart';
import '../models/delivery_order_model.dart';

class AIChatService {
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _conversationsCollection => _firestore.collection('chat_conversations');
  CollectionReference get _messagesCollection => _firestore.collection('chat_messages');
  CollectionReference get _transportOrdersCollection => _firestore.collection('transport_orders');

  // AI Service Configuration - Using Gemini only
  static const String _geminiApiKey = 'AIzaSyBaFuJUj2nReTooMQ0BNxBnTRmwMZaN_SM'; // Replace with actual key
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

  /// Send a message to the AI assistant
  Future<ChatMessageModel> sendMessageToAI({
    required String conversationId,
    required String message,
    required String userId,
    required String userName,
    List<TransportOrderModel>? activeOrders,
    List<DeliveryOrderModel>? pendingDeliveries,
    Map<String, dynamic>? transporterContext,
  }) async {
    try {
      // Create user message
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        content: message,
        senderId: userId,
        senderName: userName,
        senderType: 'user',
        timestamp: DateTime.now(),
      );

      // Save user message to Firestore
      await _messagesCollection.doc(userMessage.id).set(userMessage.toMap());

      // Update conversation
      await _updateConversation(conversationId, userMessage);

      // Generate AI response
      final aiResponse = await _generateAIResponse(
        message: message,
        userId: userId,
        userName: userName,
        activeOrders: activeOrders,
        pendingDeliveries: pendingDeliveries,
        transporterContext: transporterContext,
        conversationHistory: await _getConversationHistory(conversationId),
      );

      // Create AI message
      final aiMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        content: aiResponse['content'],
        senderId: 'ai_assistant',
        senderName: 'AI Assistant',
        senderType: 'ai',
        timestamp: DateTime.now(),
        actionType: aiResponse['actionType'],
        actionData: aiResponse['actionData'],
        metadata: aiResponse['metadata'],
      );

      // Save AI message to Firestore
      await _messagesCollection.doc(aiMessage.id).set(aiMessage.toMap());

      // Update conversation
      await _updateConversation(conversationId, aiMessage);

      return aiMessage;
    } catch (e) {
      throw Exception('Failed to send message to AI: $e');
    }
  }

  /// Generate AI response using OpenAI or Gemini
  Future<Map<String, dynamic>> _generateAIResponse({
    required String message,
    required String userId,
    required String userName,
    List<TransportOrderModel>? activeOrders,
    List<DeliveryOrderModel>? pendingDeliveries,
    Map<String, dynamic>? transporterContext,
    List<ChatMessageModel>? conversationHistory,
  }) async {
    try {
      // Build context for AI
      final context = _buildTransporterContext(
        activeOrders: activeOrders,
        pendingDeliveries: pendingDeliveries,
        transporterContext: transporterContext,
      );

      // Build conversation history
      final history = _buildConversationHistory(conversationHistory);

      // System prompt for transporter AI assistant
      const systemPrompt = '''
You are an AI assistant for transporters in the FarmLink app. You help transporters manage their delivery tasks efficiently.

Your capabilities:
1. Answer questions about deliveries, routes, and schedules
2. Provide real-time assistance for delivery management
3. Help with navigation and route optimization
4. Send emergency alerts when needed
5. Mark deliveries as completed
6. Show delivery history and earnings
7. Provide weather and traffic updates

Always be helpful, concise, and professional. When appropriate, suggest actions the transporter can take.

Available actions:
- show_route: Show route to delivery location
- mark_delivery: Mark delivery as completed
- emergency_alert: Send emergency alert
- show_history: Show delivery history
- show_earnings: Show earnings summary
- weather_update: Get weather information
- traffic_update: Get traffic information

Format your responses as JSON with:
{
  "content": "Your response text",
  "actionType": "action_name" (if applicable),
  "actionData": {action specific data},
  "metadata": {additional info}
}
''';

      // Use Gemini API only
      return await _callGemini(
        message: message,
        systemPrompt: systemPrompt,
        context: context,
        history: history,
      );
    } catch (e) {
      // Log the error for debugging
      print('AI Chat Service Error: $e');
      // Fallback response
      return {
        'content': 'I apologize, but I\'m having trouble processing your request right now. Please try again or contact support if the issue persists.',
        'actionType': null,
        'actionData': null,
        'metadata': {'error': e.toString()},
      };
    }
  }


  /// Call Gemini API
  Future<Map<String, dynamic>> _callGemini({
    required String message,
    required String systemPrompt,
    required String context,
    required String history,
  }) async {
    // TODO: Replace with actual Gemini API key
    // For now, return a mock response to test the chat functionality
    print('Mock AI Response for: $message');
    print('Context: $context');
    
    // Mock responses based on common transporter queries and actual data
    String mockResponse = _getMockResponse(message, context);
    
    return {
      'content': mockResponse,
      'actionType': null,
      'actionData': null,
      'metadata': {'mock': true},
    };
    
    /* 
    // Uncomment this section when you have a valid Gemini API key
    final response = await http.post(
      Uri.parse('$_geminiBaseUrl?key=$_geminiApiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': '$systemPrompt\n\nContext: $context\n\nHistory: $history\n\nUser: $message'
              }
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 500,
          'temperature': 0.7,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
      
      try {
        return jsonDecode(aiResponse);
      } catch (e) {
        return {
          'content': aiResponse,
          'actionType': null,
          'actionData': null,
          'metadata': null,
        };
      }
    } else {
      print('Gemini API Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }
    */
  }
  
  /// Get mock response based on user message and transporter context
  String _getMockResponse(String message, String context) {
    final lowerMessage = message.toLowerCase();
    
    // Parse context to extract transporter data
    final hasActiveOrders = context.contains('Active Orders:') && !context.contains('Active Orders: None');
    final hasPendingDeliveries = context.contains('Pending Deliveries:') && !context.contains('Pending Deliveries: None');
    final hasEarnings = context.contains('Total Earnings:') && !context.contains('Total Earnings: \$0');
    
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! I\'m your AI assistant. I can help you with your transport orders, delivery routes, and provide updates on your earnings. How can I assist you today?';
    } else if (lowerMessage.contains('order') || lowerMessage.contains('delivery') || lowerMessage.contains('next delivery')) {
      if (hasActiveOrders) {
        return 'I can see you have active transport orders! Based on your current schedule, you have deliveries to complete. Would you like me to show you the details of your current deliveries or help you plan your route?';
      } else {
        return 'I don\'t see any active transport orders at the moment. You can check for new delivery requests in your dashboard or contact support if you\'re expecting orders.';
      }
    } else if (lowerMessage.contains('route') || lowerMessage.contains('directions') || lowerMessage.contains('navigation')) {
      if (hasActiveOrders) {
        return 'I can help you find the best route for your deliveries! With your current active orders, I can suggest the most efficient path to minimize travel time and fuel costs. Would you like me to show you the optimized route?';
      } else {
        return 'I can help you plan routes once you have active deliveries. Check your dashboard for new transport orders, and I\'ll help you optimize your delivery route.';
      }
    } else if (lowerMessage.contains('earnings') || lowerMessage.contains('money') || lowerMessage.contains('payment') || lowerMessage.contains('income')) {
      if (hasEarnings) {
        return 'Great news! I can see you\'ve been earning well from your deliveries. Your total earnings show you\'re doing excellent work! Would you like me to show you a detailed breakdown of your recent earnings?';
      } else {
        return 'I can help you track your earnings! Complete more deliveries to start building your income. Check your dashboard for available transport orders.';
      }
    } else if (lowerMessage.contains('help') || lowerMessage.contains('support')) {
      return 'I\'m here to help! I can assist you with:\n• Checking your transport orders\n• Planning delivery routes\n• Tracking your earnings\n• Providing delivery updates\n• Emergency assistance\n\nWhat would you like help with?';
    } else if (lowerMessage.contains('emergency') || lowerMessage.contains('problem') || lowerMessage.contains('issue') || lowerMessage.contains('help')) {
      return 'I understand you need immediate assistance. I can help you contact support or send an emergency alert. What\'s the nature of your emergency? I\'m here to help you stay safe and resolve any issues quickly.';
    } else if (lowerMessage.contains('status') || lowerMessage.contains('current')) {
      if (hasActiveOrders) {
        return 'Your current status shows you have active transport orders. You\'re busy with deliveries! Would you like me to show you the details of your current assignments?';
      } else {
        return 'Your current status shows no active transport orders. You\'re available for new deliveries! Check your dashboard for new opportunities.';
      }
    } else if (lowerMessage.contains('see') || lowerMessage.contains('show') || lowerMessage.contains('view')) {
      if (hasActiveOrders) {
        return 'I can show you your current transport orders and delivery details. You have active assignments that need your attention. Would you like me to display your order information?';
      } else {
        return 'I can show you your dashboard, earnings, or help you find new delivery opportunities. What would you like to see?';
      }
    } else {
      return 'I understand you\'re asking about "$message". I\'m here to help with your transport and delivery needs. Based on your current status, I can assist you with orders, routes, earnings, or any other transporter-related questions. Could you be more specific about what you\'d like assistance with?';
    }
  }

  /// Build transporter context for AI
  String _buildTransporterContext({
    List<TransportOrderModel>? activeOrders,
    List<DeliveryOrderModel>? pendingDeliveries,
    Map<String, dynamic>? transporterContext,
  }) {
    final context = StringBuffer();
    
    context.writeln('Transporter Information:');
    if (transporterContext != null) {
      context.writeln('- Name: ${transporterContext['name'] ?? 'Unknown'}');
      context.writeln('- Total Earnings: \$${transporterContext['totalEarnings'] ?? 0}');
      context.writeln('- Completed Deliveries: ${transporterContext['completedDeliveries'] ?? 0}');
    }

    if (activeOrders != null && activeOrders.isNotEmpty) {
      context.writeln('\nActive Deliveries:');
      for (final order in activeOrders) {
        context.writeln('- ${order.cropName} to ${order.distributorName}');
        context.writeln('  Status: ${order.status}');
        context.writeln('  Fee: \$${order.deliveryFee ?? 0}');
        context.writeln('  Location: ${order.distributorLocation}');
      }
    }

    if (pendingDeliveries != null && pendingDeliveries.isNotEmpty) {
      context.writeln('\nPending Deliveries Available:');
      for (final delivery in pendingDeliveries) {
        context.writeln('- ${delivery.cropName} from ${delivery.farmerName}');
        context.writeln('  Quantity: ${delivery.quantity}');
        context.writeln('  Price: \$${delivery.price}');
        context.writeln('  Pickup: ${delivery.pickupLocation}');
        context.writeln('  Delivery: ${delivery.distributorLocation}');
      }
    }

    return context.toString();
  }

  /// Build conversation history
  String _buildConversationHistory(List<ChatMessageModel>? history) {
    if (history == null || history.isEmpty) return 'No previous conversation.';
    
    final historyText = StringBuffer();
    for (final msg in history.take(10)) { // Last 10 messages
      historyText.writeln('${msg.senderType}: ${msg.content}');
    }
    return historyText.toString();
  }

  /// Get conversation history
  Future<List<ChatMessageModel>> _getConversationHistory(String conversationId) async {
    try {
      final snapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update conversation with new message
  Future<void> _updateConversation(String conversationId, ChatMessageModel message) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageId': message.id,
        'lastMessageContent': message.content,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to update conversation: $e');
    }
  }

  /// Create a new conversation
  Future<String> createConversation({
    required String userId,
    required String userName,
    required String userRole,
    Map<String, dynamic>? context,
  }) async {
    try {
      final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final conversation = ChatConversationModel(
        id: conversationId,
        userId: userId,
        userName: userName,
        userRole: userRole,
        title: 'AI Assistant Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        context: context,
        tags: ['ai_assistant', userRole],
      );

      await _conversationsCollection.doc(conversationId).set(conversation.toMap());
      return conversationId;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Get user's conversations
  Future<List<ChatConversationModel>> getUserConversations(String userId) async {
    try {
      final snapshot = await _conversationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChatConversationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  /// Get conversation messages
  Future<List<ChatMessageModel>> getConversationMessages(String conversationId) async {
    try {
      final snapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Stream conversation messages
  Stream<List<ChatMessageModel>> streamConversationMessages(String conversationId) {
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Handle AI action
  Future<Map<String, dynamic>> handleAIAction(String actionType, Map<String, dynamic>? actionData) async {
    switch (actionType) {
      case 'show_route':
        return await _handleShowRoute(actionData);
      case 'mark_delivery':
        return await _handleMarkDelivery(actionData);
      case 'emergency_alert':
        return await _handleEmergencyAlert(actionData);
      case 'show_history':
        return await _handleShowHistory(actionData);
      case 'show_earnings':
        return await _handleShowEarnings(actionData);
      case 'weather_update':
        return await _handleWeatherUpdate(actionData);
      case 'traffic_update':
        return await _handleTrafficUpdate(actionData);
      default:
        return {
          'success': false,
          'message': 'Unknown action type: $actionType',
        };
    }
  }

  /// Handle show route action
  Future<Map<String, dynamic>> _handleShowRoute(Map<String, dynamic>? actionData) async {
    try {
      // Get route information from action data
      final pickupLocation = actionData?['pickupLocation'] ?? '';
      final deliveryLocation = actionData?['deliveryLocation'] ?? '';
      
      // Here you would integrate with Google Maps or your navigation service
      // For now, return a success response
      return {
        'success': true,
        'message': 'Route displayed successfully',
        'data': {
          'pickupLocation': pickupLocation,
          'deliveryLocation': deliveryLocation,
          'estimatedTime': '25 minutes',
          'distance': '15.2 km',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to show route: $e',
      };
    }
  }

  /// Handle mark delivery action
  Future<Map<String, dynamic>> _handleMarkDelivery(Map<String, dynamic>? actionData) async {
    try {
      final orderId = actionData?['orderId'] ?? '';
      
      if (orderId.isEmpty) {
        return {
          'success': false,
          'message': 'Order ID is required to mark delivery',
        };
      }

      // Update transport order status to delivered
      await _transportOrdersCollection.doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'actualDeliveryTime': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Delivery marked as completed successfully',
        'data': {
          'orderId': orderId,
          'deliveredAt': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to mark delivery: $e',
      };
    }
  }

  /// Handle emergency alert action
  Future<Map<String, dynamic>> _handleEmergencyAlert(Map<String, dynamic>? actionData) async {
    try {
      final alertType = actionData?['alertType'] ?? 'general';
      final message = actionData?['message'] ?? 'Emergency assistance needed';
      
      // Send emergency notification to admin
      await _firestore.collection('emergency_alerts').add({
        'transporterId': _auth.currentUser?.uid,
        'alertType': alertType,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'location': actionData?['location'],
      });

      return {
        'success': true,
        'message': 'Emergency alert sent successfully. Help is on the way!',
        'data': {
          'alertType': alertType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send emergency alert: $e',
      };
    }
  }

  /// Handle show history action
  Future<Map<String, dynamic>> _handleShowHistory(Map<String, dynamic>? actionData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Get delivery history
      final historySnapshot = await _transportOrdersCollection
          .where('transporterId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
          .limit(10)
          .get();

      final history = historySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'cropName': data['cropName'],
          'deliveryFee': data['deliveryFee'],
          'deliveredAt': data['deliveredAt'],
          'distributorName': data['distributorName'],
        };
      }).toList();

      return {
        'success': true,
        'message': 'Delivery history retrieved successfully',
        'data': {
          'history': history,
          'totalDeliveries': history.length,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get delivery history: $e',
      };
    }
  }

  /// Handle show earnings action
  Future<Map<String, dynamic>> _handleShowEarnings(Map<String, dynamic>? actionData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Get earnings data
      final earningsSnapshot = await _transportOrdersCollection
          .where('transporterId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .get();

      double totalEarnings = 0;
      int completedDeliveries = 0;
      Map<String, double> dailyEarnings = {};

      for (final doc in earningsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final deliveryFee = (data['deliveryFee'] as num?)?.toDouble() ?? 0;
        totalEarnings += deliveryFee;
        completedDeliveries++;

        // Group by date
        final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
        if (deliveredAt != null) {
          final dateKey = '${deliveredAt.year}-${deliveredAt.month}-${deliveredAt.day}';
          dailyEarnings[dateKey] = (dailyEarnings[dateKey] ?? 0) + deliveryFee;
        }
      }

      return {
        'success': true,
        'message': 'Earnings data retrieved successfully',
        'data': {
          'totalEarnings': totalEarnings,
          'completedDeliveries': completedDeliveries,
          'averageEarningsPerDelivery': completedDeliveries > 0 ? totalEarnings / completedDeliveries : 0,
          'dailyEarnings': dailyEarnings,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get earnings data: $e',
      };
    }
  }

  /// Handle weather update action
  Future<Map<String, dynamic>> _handleWeatherUpdate(Map<String, dynamic>? actionData) async {
    try {
      final location = actionData?['location'] ?? 'Current Location';
      
      // Here you would integrate with a weather API
      // For now, return mock weather data
      return {
        'success': true,
        'message': 'Weather update retrieved successfully',
        'data': {
          'location': location,
          'temperature': '28°C',
          'condition': 'Partly Cloudy',
          'humidity': '65%',
          'windSpeed': '12 km/h',
          'recommendation': 'Good weather for delivery. Drive safely!',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get weather update: $e',
      };
    }
  }

  /// Handle traffic update action
  Future<Map<String, dynamic>> _handleTrafficUpdate(Map<String, dynamic>? actionData) async {
    try {
      final route = actionData?['route'] ?? 'Current Route';
      
      // Here you would integrate with a traffic API
      // For now, return mock traffic data
      return {
        'success': true,
        'message': 'Traffic update retrieved successfully',
        'data': {
          'route': route,
          'status': 'Moderate Traffic',
          'estimatedDelay': '5-10 minutes',
          'alternativeRoutes': [
            'Via Main Street (2 minutes longer)',
            'Via Highway A2 (5 minutes longer)',
          ],
          'recommendation': 'Consider taking Main Street to avoid congestion',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get traffic update: $e',
      };
    }
  }

  /// Delete conversation (and its messages)
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messagesSnapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the conversation
      await _conversationsCollection.doc(conversationId).delete();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}
