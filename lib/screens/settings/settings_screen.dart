import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    // TODO: Load current language from preferences
    setState(() {
      _selectedLanguage = 'en';
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });
    // TODO: Save language preference and update app locale
  }

  Future<void> _switchRole() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetRole = authProvider.inactiveRole;
    
    if (targetRole == null) return;
    
    final success = await authProvider.switchToRole(targetRole);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${targetRole.displayName} role'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch role: ${authProvider.error ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addConsumerRole() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.addSecondaryRole(UserRole.consumer);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consumer role added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add consumer role: ${authProvider.error ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAddRoleDialog() async {
    final UserRole? selectedRole = await showDialog<UserRole>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Professional Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleOptionTile(UserRole.farmer),
              _buildRoleOptionTile(UserRole.foodDistributor),
              _buildRoleOptionTile(UserRole.transporter),
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

    if (selectedRole != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.addSecondaryRole(selectedRole);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedRole.displayName} role added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add ${selectedRole.displayName} role: ${authProvider.error ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRoleOptionTile(UserRole role) {
    return ListTile(
      leading: Icon(role.icon),
      title: Text(role.displayName),
      onTap: () => Navigator.of(context).pop(role),
    );
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (mounted) {
      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('settings')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userRole = authProvider.currentRole;
          final userProfile = authProvider.userProfile;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('profile'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              userRole?.icon ?? Icons.person,
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile?.displayName ?? userProfile?.email ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  userRole?.displayName ?? 'Unknown Role',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  userProfile?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role Management Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role Management',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Current Role Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              authProvider.currentActiveRole?.icon ?? Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Role',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    authProvider.userProfile?.roleDisplayText ?? 
                                    authProvider.currentActiveRole?.displayName ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Role Switching Options
                      if (authProvider.canSwitchRoles) ...[
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(
                            authProvider.inactiveRole?.icon ?? Icons.swap_horiz,
                            color: Colors.green,
                          ),
                          title: Text('Switch to ${authProvider.inactiveRole?.displayName ?? 'Other Role'}'),
                          subtitle: const Text('Switch to your other role'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _switchRole,
                        ),
                      ],
                      
                      // Add Secondary Role Options
                      if (authProvider.userProfile != null && !authProvider.userProfile!.hasSecondaryRole) ...[
                        const SizedBox(height: 16),
                        if (authProvider.currentActiveRole != UserRole.consumer)
                          ListTile(
                            leading: const Icon(Icons.add, color: Colors.orange),
                            title: const Text('Add Consumer Role'),
                            subtitle: const Text('Also access consumer features'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _addConsumerRole,
                          )
                        else
                          ListTile(
                            leading: const Icon(Icons.add, color: Colors.orange),
                            title: const Text('Add Professional Role'),
                            subtitle: const Text('Add Farmer, Distributor, or Transporter role'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _showAddRoleDialog,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Language Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('language'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageOption('English', 'en', '🇺🇸'),
                      _buildLanguageOption('සිංහල', 'si', '🇱🇰'),
                      _buildLanguageOption('தமிழ்', 'ta', '🇮🇳'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Other Settings
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(l10n.get('notifications')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to notifications settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: Text(l10n.get('privacy')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to privacy settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: Text(l10n.get('help')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to help
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: Text(l10n.get('about')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to about
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(
                      l10n.get('logout'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(String name, String code, String flag) {
    final isSelected = _selectedLanguage == code;
    
    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: () => _changeLanguage(code),
    );
  }
}
