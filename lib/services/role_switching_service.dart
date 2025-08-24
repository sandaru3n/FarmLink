import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../screens/dashboards/dashboard_router.dart';

class RoleSwitchingService {
  static Future<bool> switchRole(BuildContext context, UserRole newRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.switchToRole(newRole);
      
      if (success && context.mounted) {
        // Navigate to the new dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardRouter(),
          ),
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${newRole.displayName} role'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        return true;
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to switch role: ${authProvider.error ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching role: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  static void showRoleSwitchDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final inactiveRole = authProvider.inactiveRole;
    
    if (inactiveRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other role available to switch to'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Switch Role'),
          content: Text('Do you want to switch to ${inactiveRole.displayName} role?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                switchRole(context, inactiveRole);
              },
              child: const Text('Switch'),
            ),
          ],
        );
      },
    );
  }

  static Widget getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return const Icon(Icons.agriculture, color: Colors.green);
      case UserRole.consumer:
        return const Icon(Icons.shopping_cart, color: Colors.blue);
      case UserRole.foodDistributor:
        return const Icon(Icons.store, color: Colors.orange);
      case UserRole.transporter:
        return const Icon(Icons.local_shipping, color: Colors.purple);
    }
  }

  static Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return Colors.green;
      case UserRole.consumer:
        return Colors.blue;
      case UserRole.foodDistributor:
        return Colors.orange;
      case UserRole.transporter:
        return Colors.purple;
    }
  }
}
