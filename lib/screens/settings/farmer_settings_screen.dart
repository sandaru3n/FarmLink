import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';
import '../auth/login_screen.dart';
import '../../services/flexible_role_switching_service.dart';

class FarmerSettingsScreen extends StatefulWidget {
  const FarmerSettingsScreen({super.key});

  @override
  State<FarmerSettingsScreen> createState() => _FarmerSettingsScreenState();
}

class _FarmerSettingsScreenState extends State<FarmerSettingsScreen> {
  String _selectedLanguage = 'en';
  bool _isFarmerSettingsExpanded = false;
  bool _isLanguageExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    setState(() {
      _selectedLanguage = languageProvider.locale.languageCode;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    // Save language preference and update app locale
    await languageProvider.changeLocale(Locale(languageCode, ''));
    
    // Show confirmation
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('language_changed')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _switchRole() async {
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
      return;
    }

    final availableRoles = FlexibleRoleSwitchingService.getAvailableRolesToSwitchForUser(context);
    
    if (availableRoles.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade500,
                        Colors.green.shade700,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Switch Role',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current: ${currentRole.displayName}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select a role to switch to:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...availableRoles.map((role) => _buildRoleOptionCard(dialogContext, role)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOptionCard(BuildContext dialogContext, UserRole role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(role).shade500,
            _getRoleColor(role).shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getRoleColor(role).shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Navigator.of(dialogContext).pop();
            final result = await FlexibleRoleSwitchingService.switchToRole(context, role);
            if (result) {
              // Role switched successfully
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    role.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Switch to ${role.displayName} role',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MaterialColor _getRoleColor(UserRole role) {
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.green.shade700,
          elevation: 0,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: authProvider.userProfile?.uid != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(authProvider.userProfile!.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          UserModel? userProfile = authProvider.userProfile;
          
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              final dataWithId = {...data, 'uid': snapshot.data!.id};
              userProfile = UserModel.fromMap(dataWithId);
            }
          }

          return Column(
            children: [
              _buildModernHeader(userProfile),
              Expanded(
                child: Container(
                  color: Colors.grey.shade50,
                  child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade300,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                            child: const Icon(
                              Icons.agriculture,
                          size: 32,
                          color: Colors.white,
                            ),
                          ),
                      const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile?.displayName ?? userProfile?.email ?? 'Farmer',
                              style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade600,
                                    Colors.green.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                  'Farmer',
                                  style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                                Text(
                                  userProfile?.email ?? '',
                                  style: TextStyle(
                                color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role Management Section - Hide for primary Consumer users
              if (userProfile?.primaryRole != UserRole.consumer && 
                  FlexibleRoleSwitchingService.getAvailableRolesToSwitchForUser(context).isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                        Container(
                              padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Role Management',
                                      style: TextStyle(
                                fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildSettingTile(
                          icon: Icons.agriculture,
                          title: 'Current: Farmer',
                          subtitle: FlexibleRoleSwitchingService.getRoleSwitchingDescriptionForUser(context),
                          onTap: _switchRole,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Farmer Specific Settings
              _buildExpandableSection(
                title: 'Farmer Settings',
                icon: Icons.agriculture,
                isExpanded: _isFarmerSettingsExpanded,
                onToggle: () {
                  setState(() {
                    _isFarmerSettingsExpanded = !_isFarmerSettingsExpanded;
                  });
                },
                content: Column(
                    children: [
                    _buildSettingTile(
                      icon: Icons.agriculture,
                      title: 'Farm Details',
                      subtitle: 'Manage your farm information',
                        onTap: () {
                          // TODO: Navigate to farm details
                        },
                      ),
                    const SizedBox(height: 10),
                    _buildSettingTile(
                      icon: Icons.settings,
                      title: 'Crop Management',
                      subtitle: 'Configure crop settings',
                        onTap: () {
                          // TODO: Navigate to crop management
                        },
                      ),
                    const SizedBox(height: 10),
                    _buildSettingTile(
                      icon: Icons.location_on,
                      title: 'Location Settings',
                      subtitle: 'Set your farm location',
                        onTap: () {
                          // TODO: Navigate to location settings
                        },
                      ),
                    ],
                ),
              ),
              const SizedBox(height: 16),

              // Language Section
              _buildExpandableSection(
                title: l10n.get('language'),
                icon: Icons.language,
                isExpanded: _isLanguageExpanded,
                onToggle: () {
                  setState(() {
                    _isLanguageExpanded = !_isLanguageExpanded;
                  });
                },
                content: Column(
                    children: [
                    _buildLanguageOption('English', 'en'),
                    _buildLanguageOption('සිංහල', 'si'),
                    _buildLanguageOption('தமிழ்', 'ta'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Other Settings
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                      _buildSettingTile(
                        icon: Icons.notifications,
                        title: l10n.get('notifications'),
                        subtitle: 'Manage notification preferences',
                      onTap: () {
                        // TODO: Navigate to notifications settings
                      },
                    ),
                      const SizedBox(height: 10),
                      _buildSettingTile(
                        icon: Icons.privacy_tip,
                        title: l10n.get('privacy'),
                        subtitle: 'Privacy and security settings',
                      onTap: () {
                        // TODO: Navigate to privacy settings
                      },
                    ),
                      const SizedBox(height: 10),
                      _buildSettingTile(
                        icon: Icons.help,
                        title: l10n.get('help'),
                        subtitle: 'Get help and support',
                      onTap: () {
                        // TODO: Navigate to help
                      },
                    ),
                      const SizedBox(height: 10),
                      _buildSettingTile(
                        icon: Icons.info,
                        title: l10n.get('about'),
                        subtitle: 'App information and version',
                      onTap: () {
                        // TODO: Navigate to about
                      },
                    ),
                  ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade500,
                      Colors.red.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade300,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      const Icon(Icons.logout, size: 24),
                      const SizedBox(width: 10),
                    Text(
                      l10n.get('logout'),
                      style: const TextStyle(
                          fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(UserModel? userProfile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.green.shade700,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                AppLocalizations.of(context).get('settings'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: content,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String name, String code) {
    final isSelected = _selectedLanguage == code;
    
    return InkWell(
      onTap: () => _changeLanguage(code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language,
              color: isSelected ? Colors.green.shade600 : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
        name,
        style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                  color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
