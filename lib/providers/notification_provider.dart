import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  
  // Stream subscriptions
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  
  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load user notifications
  void loadUserNotifications(String userId) {
    _setLoading(true);
    _clearError();
    
    try {
      // Cancel existing subscriptions
      _notificationsSubscription?.cancel();
      _unreadCountSubscription?.cancel();
      
      // Subscribe to notifications stream
      _notificationsSubscription = _notificationService
          .getUserNotifications(userId)
          .listen(
        (notifications) {
          _notifications = notifications;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError(error.toString());
          _setLoading(false);
        },
      );
      
      // Subscribe to unread count stream
      _unreadCountSubscription = _notificationService
          .getUnreadNotificationCount(userId)
          .listen(
        (count) {
          _unreadCount = count;
          notifyListeners();
        },
        onError: (error) {
          print('Error loading unread count: $error');
        },
      );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      _setLoading(true);
      await _notificationService.markAllNotificationsAsRead(userId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    try {
      _setLoading(true);
      await _notificationService.deleteAllNotifications(userId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}

