import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'farmer/farmer_dashboard.dart';
import 'consumer/consumer_dashboard.dart';
import 'fooddistributor/fooddistributor_dashboard.dart';
import 'transporter/transporter_dashboard.dart';
import 'dashboard_router.dart';

class RealTimeDashboardWrapper extends StatefulWidget {
  final Widget Function(UserModel? userProfile) dashboardBuilder;

  const RealTimeDashboardWrapper({
    super.key,
    required this.dashboardBuilder,
  });

  @override
  State<RealTimeDashboardWrapper> createState() => _RealTimeDashboardWrapperState();
}

class _RealTimeDashboardWrapperState extends State<RealTimeDashboardWrapper> {
  UserRole? _previousRole;
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not authenticated'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('User profile not found'),
            ),
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

          return widget.dashboardBuilder(userProfile);
        } catch (e) {
          return Scaffold(
            body: Center(
              child: Text('Error parsing user data: $e'),
            ),
          );
        }
      },
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
