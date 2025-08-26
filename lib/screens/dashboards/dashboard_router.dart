import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'farmer/farmer_dashboard.dart';
import 'consumer/consumer_dashboard.dart';
import 'fooddistributor/fooddistributor_dashboard.dart';
import 'transporter/transporter_dashboard.dart';
import 'real_time_dashboard_wrapper.dart';

class DashboardRouter extends StatefulWidget {
  const DashboardRouter({super.key});

  @override
  State<DashboardRouter> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardRouter> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authProvider.isLoggedIn) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in'),
            ),
          );
        }

        return RealTimeDashboardWrapper(
          dashboardBuilder: (userProfile) {
            if (userProfile == null) {
              return const Scaffold(
                body: Center(
                  child: Text('User profile not found'),
                ),
              );
            }

            final userRole = userProfile.currentActiveRole;

            // Route to role-specific dashboard
            switch (userRole) {
              case UserRole.farmer:
                return const FarmerDashboard();
              case UserRole.consumer:
                return const ConsumerDashboard();
              case UserRole.foodDistributor:
                return const FoodDistributorDashboard();
              case UserRole.transporter:
                return const TransporterDashboard();
              default:
                // Fallback to a generic dashboard or error screen
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Dashboard'),
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No role assigned',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please contact support to assign a role',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}

// Extension method to get the appropriate dashboard widget based on role
extension DashboardExtension on UserRole {
  Widget getDashboardWidget() {
    switch (this) {
      case UserRole.farmer:
        return const FarmerDashboard();
      case UserRole.consumer:
        return const ConsumerDashboard();
      case UserRole.foodDistributor:
        return const FoodDistributorDashboard();
      case UserRole.transporter:
        return const TransporterDashboard();
    }
  }
}
