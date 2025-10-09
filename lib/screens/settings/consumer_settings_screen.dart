import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';
import '../auth/login_screen.dart';
import '../dashboards/dashboard_router.dart';
import '../../services/flexible_role_switching_service.dart';

class ConsumerSettingsScreen extends StatefulWidget {
  const ConsumerSettingsScreen({super.key});

  @override
  State<ConsumerSettingsScreen> createState() => _ConsumerSettingsScreenState();
}

class _ConsumerSettingsScreenState extends State<ConsumerSettingsScreen> {
  String _selectedLanguage = 'en';
  bool _isConsumerSettingsExpanded = false;
  bool _isLanguageExpanded = false;

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
    await FlexibleRoleSwitchingService.showRoleSwitchingDialog(context);
    // Real-time wrapper will handle updates automatically
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
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        body: Column(
          children: [
            _buildModernHeader(context),
            const Expanded(
              child: Center(
                child: Text('User not authenticated'),
              ),
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                _buildModernHeader(context),
                Expanded(
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                ),
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                _buildModernHeader(context),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Column(
              children: [
                _buildModernHeader(context),
                const Expanded(
                  child: Center(
                    child: Text('User profile not found'),
                  ),
                ),
              ],
            );
          }

          try {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userProfile = UserModel.fromMap(userData);

            return Column(
              children: [
                _buildModernHeader(context),
                
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
              // Profile Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (userProfile?.displayName ?? userProfile?.email ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile?.displayName ?? userProfile?.email ?? 'Consumer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user, size: 14, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Consumer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.email, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  userProfile?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Role Management Section - Hide for primary Consumer users
              if (userProfile?.primaryRole != UserRole.consumer && 
                  FlexibleRoleSwitchingService.getAvailableRolesToSwitchForUser(context).isNotEmpty) ...[
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
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                color: Colors.blue,
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
                                    const Text(
                                      'Consumer',
                                      style: TextStyle(
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
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.swap_horiz, color: Colors.green),
                          title: const Text('Switch Role'),
                          subtitle: Text(FlexibleRoleSwitchingService.getRoleSwitchingDescriptionForUser(context)),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _switchRole,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Consumer Specific Settings
              _buildExpandableSection(
                title: 'Consumer Settings',
                icon: Icons.tune,
                iconColor: Colors.blue.shade600,
                isExpanded: _isConsumerSettingsExpanded,
                onTap: () {
                  setState(() {
                    _isConsumerSettingsExpanded = !_isConsumerSettingsExpanded;
                  });
                },
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.location_on,
                      title: 'Delivery Address',
                      subtitle: 'Manage your delivery addresses',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildSettingTile(
                      icon: Icons.payment,
                      title: 'Payment Methods',
                      subtitle: 'Manage your payment options',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildSettingTile(
                      icon: Icons.favorite,
                      title: 'Preferences',
                      subtitle: 'Set your shopping preferences',
                      onTap: () {},
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Language Section
              _buildExpandableSection(
                title: l10n.get('language'),
                icon: Icons.language,
                iconColor: Colors.purple.shade600,
                isExpanded: _isLanguageExpanded,
                onTap: () {
                  setState(() {
                    _isLanguageExpanded = !_isLanguageExpanded;
                  });
                },
                child: Column(
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.notifications_outlined,
                      title: l10n.get('notifications'),
                      subtitle: 'Manage notification preferences',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildSettingTile(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.get('privacy'),
                      subtitle: 'Privacy and security settings',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildSettingTile(
                      icon: Icons.help_outline,
                      title: l10n.get('help'),
                      subtitle: 'Help and support',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildSettingTile(
                      icon: Icons.info_outline,
                      title: l10n.get('about'),
                      subtitle: 'About FarmLink',
                      onTap: () {},
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        l10n.get('logout'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          } catch (e) {
            return Column(
              children: [
                _buildModernHeader(context),
                Expanded(
                  child: Center(
                    child: Text('Error parsing user data: $e'),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade600,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [iconColor, iconColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                      size: 26,
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
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      child,
                    ],
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
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast 
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String name, String code) {
    final isSelected = _selectedLanguage == code;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeLanguage(code),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.purple.shade300 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.language,
                    color: isSelected ? Colors.purple.shade700 : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                    color: isSelected ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
