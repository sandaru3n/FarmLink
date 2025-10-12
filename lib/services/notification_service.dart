import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Collection references
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> initialize(String? userId) async {
    await _requestPermission();
    await _configureLocalNotifications();
    await _configureForegroundPresentation();
    await _setupForegroundMessageHandler();
    await _saveFcmToken(userId);
    
    // Print FCM token for testing
    final token = await getFCMToken();
    print('═══════════════════════════════════════════════════════');
    print('📱 FCM REGISTRATION TOKEN FOR TESTING:');
    print('═══════════════════════════════════════════════════════');
    print(token ?? 'No token available');
    print('═══════════════════════════════════════════════════════');
    print('📋 Copy this token to use in Firebase Console for testing');
    print('═══════════════════════════════════════════════════════');
  }
  
  // Get FCM token for testing
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
  
  // Configure local notifications for foreground display
  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'farmlink_notifications',
        'FarmLink Notifications',
        description: 'This channel is used for FarmLink app notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }
  
  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Add navigation logic here if needed
  }
  
  // Setup foreground message handler
  Future<void> _setupForegroundMessageHandler() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _showForegroundNotification(message);
    });
  }
  
  // Show notification when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'farmlink_notifications',
            'FarmLink Notifications',
            channelDescription: 'This channel is used for FarmLink app notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: const Color(0xFF4CB050),
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _configureForegroundPresentation() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _saveFcmToken(String? userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      if (userId == null || userId.isEmpty) return;

      // Save token under users/{uid}/tokens/{token}
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token);
      await docRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      }, SetOptions(merge: true));

      // Also keep the latest token on user doc for convenience
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final refreshRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .doc(newToken);
        await refreshRef.set({
          'token': newToken,
          'refreshedAt': FieldValue.serverTimestamp(),
          'platform': Platform.operatingSystem,
        }, SetOptions(merge: true));

        await _firestore.collection('users').doc(userId).set({
          'fcmToken': newToken,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      // Intentionally silent to avoid blocking auth flow
    }
  }

  // Send notification to all distributors about a new active crop
  Future<void> notifyDistributorsAboutNewCrop({
    required String cropId,
    required String cropName,
    required double quantity,
    required String farmerId,
  }) async {
    try {
      // Get all distributor users
      final distributorIds = await _getAllDistributorIds();
      
      if (distributorIds.isEmpty) {
        print('No distributors found to notify');
        return;
      }

      // Create notification for each distributor
      final batch = _firestore.batch();
      final now = DateTime.now();
      int notificationsCreated = 0;

      for (String distributorId in distributorIds) {
        // Skip the farmer who created the crop
        if (distributorId == farmerId) continue;

        final notificationRef = _notificationsCollection.doc();
        final notification = NotificationModel(
          id: notificationRef.id,
          userId: distributorId,
          type: 'new_crop',
          title: 'New Crop Available',
          message: '$cropName ($quantity kg) is now available for bidding!',
          data: {
            'cropId': cropId,
            'cropName': cropName,
            'quantity': quantity,
            'farmerId': farmerId,
          },
          isRead: false,
          createdAt: now,
        );

        batch.set(notificationRef, notification.toFirestore());
        notificationsCreated++;
      }

      await batch.commit();
      print('✅ Created $notificationsCreated notification documents for new crop: $cropName');
      print('📱 Push notifications will be sent by Firebase Cloud Functions');
      print('   If Cloud Functions not set up yet, see: CLOUD_FUNCTIONS_SETUP.md');
    } catch (e) {
      print('❌ Error creating notifications: $e');
    }
  }

  // Get all distributor user IDs
  Future<List<String>> _getAllDistributorIds() async {
    try {
      // Query users collection where currentActiveRole is foodDistributor
      final querySnapshot = await _usersCollection
          .where('currentActiveRole', isEqualTo: 'foodDistributor')
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting distributor IDs: $e');
      return [];
    }
  }

  // Get notifications for a specific user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get unread notification count for a user
  Stream<int> getUnreadNotificationCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final unreadNotifications = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadNotifications.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final userNotifications = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      if (userNotifications.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }
}


