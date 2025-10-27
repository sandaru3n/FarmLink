import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../providers/chat_provider.dart';
import '../../providers/transport_order_provider.dart';
import '../../providers/delivery_order_provider.dart';
import '../../models/chat_message_model.dart';
import '../../utils/app_localizations.dart';
import '../../services/voice_service.dart';

class AIChatAssistantScreen extends StatefulWidget {
  const AIChatAssistantScreen({super.key});

  @override
  State<AIChatAssistantScreen> createState() => _AIChatAssistantScreenState();
}

class _AIChatAssistantScreenState extends State<AIChatAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: Curves.easeInOut),
    );

    // Initialize chat with transporter context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
      _voiceService.initialize();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);

    await chatProvider.initialize(
      activeOrders: [
        ...transportOrderProvider.acceptedTransportOrders,
        ...transportOrderProvider.inTransitTransportOrders,
      ],
      pendingDeliveries: deliveryOrderProvider.pendingDeliveryOrders,
      context: {
        'totalEarnings': transportOrderProvider.deliveredTransportOrders
            .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0)),
        'completedDeliveries': transportOrderProvider.deliveredTransportOrders.length,
        'name': 'Transporter',
      },
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Clear input
    _messageController.clear();
    
    // Send message
    await chatProvider.sendMessage(message);
    
    // Scroll to bottom
    _scrollToBottom();
  }

  Future<void> _startVoiceInput() async {
    try {
      await _voiceService.startListening(
        onResult: (text) {
          _messageController.text = text;
        },
        onPartialResult: (text) {
          _messageController.text = text;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice input error: $e')),
      );
    }
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
  }

  Future<void> _speakText(String text) async {
    try {
      await _voiceService.speak(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text-to-speech error: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LineAwesomeIcons.robot,
                color: Colors.deepPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get('ai_assistant'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.get('ai_assistant_subtitle'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).refresh();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LineAwesomeIcons.exclamation_triangle,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chatProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      chatProvider.clearError();
                      _initializeChat();
                    },
                    child: Text(l10n.get('retry')),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Welcome message
              _buildWelcomeMessage(),
              
              // Chat messages
              Expanded(
                child: StreamBuilder<List<ChatMessageModel>>(
                  stream: chatProvider.streamCurrentMessages(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final messages = snapshot.data!;
                      
                      if (messages.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length + (chatProvider.isSendingMessage ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && chatProvider.isSendingMessage) {
                            return _buildTypingIndicator();
                          }
                          
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      );
                    }
                    
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              
              // Message input
              _buildMessageInput(chatProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LineAwesomeIcons.robot,
                color: Colors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.get('ai_assistant_welcome'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.get('ai_assistant_description'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip(l10n.get('next_delivery')),
              _buildQuickActionChip(l10n.get('show_route')),
              _buildQuickActionChip(l10n.get('mark_delivery')),
              _buildQuickActionChip(l10n.get('emergency_help')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.deepPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LineAwesomeIcons.comments,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.get('no_messages_yet'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.get('start_conversation'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.senderType == 'user';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LineAwesomeIcons.robot,
                color: Colors.deepPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (message.actionType != null) ...[
                    const SizedBox(height: 8),
                    _buildActionButton(message),
                  ],
                  if (!isUser) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _speakText(message.content),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LineAwesomeIcons.volume_up,
                              color: Colors.deepPurple,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LineAwesomeIcons.user,
                color: Colors.deepPurple,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(ChatMessageModel message) {
    return ElevatedButton.icon(
      onPressed: () {
        Provider.of<ChatProvider>(context, listen: false)
            .handleAIAction(message.actionType!, message.actionData);
      },
      icon: Icon(_getActionIcon(message.actionType!)),
      label: Text(_getActionLabel(message.actionType!)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'show_route':
        return LineAwesomeIcons.map_marker;
      case 'mark_delivery':
        return LineAwesomeIcons.check;
      case 'emergency_alert':
        return LineAwesomeIcons.exclamation_triangle;
      case 'show_history':
        return LineAwesomeIcons.history;
      case 'show_earnings':
        return LineAwesomeIcons.dollar_sign;
      case 'weather_update':
        return LineAwesomeIcons.cloud;
      case 'traffic_update':
        return LineAwesomeIcons.traffic_light;
      default:
        return LineAwesomeIcons.info_circle;
    }
  }

  String _getActionLabel(String actionType) {
    final l10n = AppLocalizations.of(context);
    switch (actionType) {
      case 'show_route':
        return l10n.get('show_route');
      case 'mark_delivery':
        return l10n.get('mark_delivery');
      case 'emergency_alert':
        return l10n.get('emergency_alert');
      case 'show_history':
        return l10n.get('show_history');
      case 'show_earnings':
        return l10n.get('show_earnings');
      case 'weather_update':
        return l10n.get('weather_update');
      case 'traffic_update':
        return l10n.get('traffic_update');
      default:
        return l10n.get('action');
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LineAwesomeIcons.robot,
              color: Colors.deepPurple,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Voice input indicator
          if (_voiceService.isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LineAwesomeIcons.microphone,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Listening...',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _stopVoiceInput,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LineAwesomeIcons.stop,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: l10n.get('type_message'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              
              // Voice input button
              Container(
                decoration: BoxDecoration(
                  color: _voiceService.isListening ? Colors.red : Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: _voiceService.isListening ? _stopVoiceInput : _startVoiceInput,
                  icon: Icon(
                    _voiceService.isListening ? LineAwesomeIcons.stop : LineAwesomeIcons.microphone,
                    color: _voiceService.isListening ? Colors.white : Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Send button
              Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: chatProvider.isSendingMessage ? null : _sendMessage,
                  icon: chatProvider.isSendingMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          LineAwesomeIcons.paper_plane,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
