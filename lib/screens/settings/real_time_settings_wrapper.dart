import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../dashboards/dashboard_router.dart';

class RealTimeSettingsWrapper extends StatefulWidget {
  final Widget Function(UserModel? userProfile) settingsBuilder;
  final String title;
  final Color themeColor;

  const RealTimeSettingsWrapper({
    super.key,
    required this.settingsBuilder,
    required this.title,
    required this.themeColor,
  });

  @override
  State<RealTimeSettingsWrapper> createState() => _RealTimeSettingsWrapperState();
}

class _RealTimeSettingsWrapperState extends State<RealTimeSettingsWrapper> {
  UserRole? _previousRole;
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: widget.themeColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('User not authenticated'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('User profile not found'),
            );
          }

          try {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userProfile = UserModel.fromMap(userData);
            final currentActiveRole = userProfile.currentActiveRole;

            // Initialize previous role if not set
            if (_previousRole == null) {
              _previousRole = currentActiveRole;
            }

            // Check if role has actually changed and we haven't already navigated
            if (currentActiveRole != null && 
                _previousRole != null && 
                _previousRole != currentActiveRole && 
                !_hasNavigated) {
              
              // Mark that we've navigated to prevent multiple navigations
              _hasNavigated = true;
              
              // Role has changed, navigate back to DashboardRouter to preserve navigation menu
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateToDashboardRouter(context);
              });
            }

            // Update the previous role
            _previousRole = currentActiveRole;

            // Update AuthProvider with the latest user profile (but don't trigger navigation)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_hasNavigated) {
                authProvider.updateUserProfile(userProfile);
              }
            });

            return widget.settingsBuilder(userProfile);
          } catch (e) {
            return Center(
              child: Text('Error parsing user data: $e'),
            );
          }
        },
      ),
    );
  }

  void _navigateToDashboardRouter(BuildContext context) {
    // Navigate back to DashboardRouter to preserve navigation menu
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const DashboardRouter(),
        settings: const RouteSettings(name: 'DashboardRouter'),
      ),
      (route) => false, // Remove all previous routes
    );
  }
}
