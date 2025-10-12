import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/fcm_token_display.dart';
import '../providers/notification_provider.dart';

class TestNotificationScreen extends StatelessWidget {
  const TestNotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Push Notifications'),
        backgroundColor: const Color(0xFF4CB050),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Display Card
            const FCMTokenDisplay(),
            
            // Instructions Card
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF4CB050)),
                        SizedBox(width: 8),
                        Text(
                          'How to Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      '1',
                      'Copy the FCM token above',
                      Icons.copy,
                    ),
                    _buildStep(
                      '2',
                      'Open Firebase Console → Messaging',
                      Icons.cloud,
                    ),
                    _buildStep(
                      '3',
                      'Click "New Campaign" → "Notification messages"',
                      Icons.campaign,
                    ),
                    _buildStep(
                      '4',
                      'Select "Send test message"',
                      Icons.send,
                    ),
                    _buildStep(
                      '5',
                      'Paste your FCM token and click "Test"',
                      Icons.check_circle,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.tips_and_updates, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Test in all three states: foreground, background, and terminated',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Notification Statistics Card
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bar_chart, color: Color(0xFF4CB050)),
                            SizedBox(width: 8),
                            Text(
                              'Notification Statistics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Total Notifications',
                          '${notificationProvider.notifications.length}',
                          Icons.notifications,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Unread Notifications',
                          '${notificationProvider.unreadCount}',
                          Icons.notifications_active,
                          isHighlighted: notificationProvider.unreadCount > 0,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Read Notifications',
                          '${notificationProvider.notifications.length - notificationProvider.unreadCount}',
                          Icons.done_all,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Quick Actions Card
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.touch_app, color: Color(0xFF4CB050)),
                        SizedBox(width: 8),
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                        icon: const Icon(Icons.list),
                        label: const Text('View All Notifications'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CB050),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4CB050),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Icon(icon, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: isHighlighted ? Colors.orange : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.orange[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.orange[900] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

