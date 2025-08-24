import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../screens/dashboards/dashboard_router.dart';
import '../screens/settings/farmer_settings_screen.dart';
import '../screens/settings/consumer_settings_screen.dart';
import '../screens/settings/fooddistributor_settings_screen.dart';
import '../screens/settings/transporter_settings_screen.dart';

class FlexibleRoleSwitchingService {
  // Get available roles to switch to based on user's primary and secondary roles
  static List<UserRole> getAvailableRolesToSwitchForUser(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    
    if (userProfile == null) {
      return [];
    }
    
    // Primary Consumer users cannot switch roles
    if (userProfile.primaryRole == UserRole.consumer) {
      return [];
    }
    
    // Only show the role that can be switched to (not the current active role)
    if (userProfile.currentActiveRole == UserRole.consumer) {
      return [userProfile.primaryRole]; // Can switch back to primary role
    } else {
      return [UserRole.consumer]; // Can switch to Consumer
    }
  }

  // Legacy method for backward compatibility (deprecated)
  static List<UserRole> getAvailableRolesToSwitch(UserRole currentRole) {
    // This method is deprecated - use getAvailableRolesToSwitchForUser instead
    return [];
  }

  // Check if user can switch to a specific role
  static bool canSwitchToRole(UserRole currentRole, UserRole targetRole) {
    // This method is deprecated - use the context-aware version instead
    return false;
  }

  // Check if user can switch to a specific role (context-aware)
  static bool canSwitchToRoleForUser(BuildContext context, UserRole targetRole) {
    final availableRoles = getAvailableRolesToSwitchForUser(context);
    return availableRoles.contains(targetRole);
  }

  // Show role switching dialog
  static Future<bool> showRoleSwitchingDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentRole = authProvider.currentActiveRole;
    final userProfile = authProvider.userProfile;
    
    if (currentRole == null || userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active role found'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final availableRoles = getAvailableRolesToSwitchForUser(context);
    
    if (availableRoles.isEmpty) {
      if (userProfile.primaryRole == UserRole.consumer) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consumer role cannot be switched to other roles'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No other roles available to switch to'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Switch Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are currently a ${currentRole.displayName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a role to switch to:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...availableRoles.map((role) => _buildRoleOption(context, role)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    
    // Return the result from the dialog
    return result ?? false;
  }

  // Build role option widget
  static Widget _buildRoleOption(BuildContext context, UserRole role) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          role.icon,
          color: _getRoleColor(role),
          size: 24,
        ),
        title: Text(
          role.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Switch to ${role.displayName} role'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          Navigator.of(context).pop();
          final result = await switchToRole(context, role);
          // Return the result through the dialog
          Navigator.of(context).pop(result);
        },
      ),
    );
  }

  // Switch to specific role
  static Future<bool> switchToRole(BuildContext context, UserRole targetRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentRole = authProvider.currentActiveRole;
    
    if (currentRole == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active role found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    // Check if switching is allowed
    if (!canSwitchToRoleForUser(context, targetRole)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot switch from ${currentRole.displayName} to ${targetRole.displayName}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

         try {
       // Show loading indicator
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Row(
               children: [
                 const SizedBox(
                   width: 20,
                   height: 20,
                   child: CircularProgressIndicator(
                     strokeWidth: 2,
                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Text('Switching to ${targetRole.displayName}...'),
               ],
             ),
             backgroundColor: _getRoleColor(targetRole),
             duration: const Duration(seconds: 1),
           ),
         );
       }

       // Perform the role switch
       final success = await authProvider.switchToRoleFlexible(targetRole);
      
             if (success && context.mounted) {
         // Check if we're currently on a settings screen
         final currentRoute = ModalRoute.of(context);
         final isOnSettingsScreen = currentRoute?.settings.name?.contains('Settings') ?? false;
         
         // Real-time wrappers will handle navigation automatically
         // No need for manual navigation here
        
        // Show success message with secondary role information
        String message = 'Successfully switched to ${targetRole.displayName} role';
        
        // Check if this was a role switch that updated the secondary role
        final userProfile = authProvider.userProfile;
        if (userProfile != null && userProfile.hasSecondaryRole) {
          if (targetRole == UserRole.consumer) {
            // When switching to Consumer, show the primary role as secondary
            message = 'Switched to Consumer. ${userProfile.primaryRole.displayName} is now your secondary role.';
          } else if (userProfile.primaryRole == UserRole.consumer) {
            // When switching from Consumer to another role
            message = 'Switched to ${targetRole.displayName}. Consumer is now your secondary role.';
          } else {
            // When switching between non-Consumer roles
            message = 'Switched to ${targetRole.displayName}. Consumer is now your secondary role.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message),
                ),
              ],
            ),
            backgroundColor: _getRoleColor(targetRole),
            duration: const Duration(seconds: 4),
          ),
        );
        
        return true;
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Failed to switch role: ${authProvider.error ?? 'Unknown error'}'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
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

  // Get role-specific color
  static Color _getRoleColor(UserRole role) {
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

  // Get role switching description
  static String getRoleSwitchingDescription(UserRole currentRole) {
    // This method is deprecated - use the context-aware version instead
    return 'No roles available';
  }

  // Get role switching description (context-aware)
  static String getRoleSwitchingDescriptionForUser(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    
    if (userProfile == null) {
      return 'No roles available';
    }
    
    final availableRoles = getAvailableRolesToSwitchForUser(context);
    if (availableRoles.isEmpty) {
      if (userProfile.primaryRole == UserRole.consumer) {
        return 'Consumer role cannot be switched';
      }
      return 'No other roles available';
    }
    
    // Show only the role that can be switched to (not current role)
    final switchableRole = availableRoles.first;
    return 'Switch to: ${switchableRole.displayName}';
  }

  // Navigate to role-specific settings screen
  static void _navigateToRoleSettings(BuildContext context, UserRole targetRole) {
    Widget settingsScreen;
    
    switch (targetRole) {
      case UserRole.farmer:
        settingsScreen = const FarmerSettingsScreen();
        break;
      case UserRole.consumer:
        settingsScreen = const ConsumerSettingsScreen();
        break;
      case UserRole.foodDistributor:
        settingsScreen = const FoodDistributorSettingsScreen();
        break;
      case UserRole.transporter:
        settingsScreen = const TransporterSettingsScreen();
        break;
    }
    
    // Replace current settings screen with new role's settings screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => settingsScreen,
        settings: RouteSettings(name: '${targetRole.displayName}Settings'),
      ),
    );
  }

  // Add secondary role for user
  static Future<bool> addSecondaryRole(BuildContext context, UserRole secondaryRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    
    if (userProfile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    
    // Check if user can add this secondary role
    if (!userProfile.canAddSecondaryRole(secondaryRole)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot add ${secondaryRole.displayName} as secondary role'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    
    try {
      final success = await authProvider.addSecondaryRole(secondaryRole);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${secondaryRole.displayName} as secondary role'),
            backgroundColor: _getRoleColor(secondaryRole),
            duration: const Duration(seconds: 3),
          ),
        );
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add secondary role: ${authProvider.error ?? 'Unknown error'}'),
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
            content: Text('Error adding secondary role: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  // Debug method to test live updates
  static void testLiveUpdate(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentRole = authProvider.currentActiveRole;
    
    if (currentRole != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current role: ${currentRole.displayName}'),
          backgroundColor: _getRoleColor(currentRole),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
