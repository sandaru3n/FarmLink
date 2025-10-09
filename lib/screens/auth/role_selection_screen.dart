import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';
import '../dashboards/dashboard_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  Future<void> _continueWithRole() async {
    if (_selectedRole == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.createUserProfile(
      role: _selectedRole!,
    );

    if (success && mounted) {
      await authProvider.markOnboardingCompleted();
              Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardRouter(),
          ),
          (route) => false,
        );
    }
  }

  Widget _buildRoleCard(UserRole role, String title, String description, IconData icon) {
    final l10n = AppLocalizations.of(context);
    final isSelected = _selectedRole == role;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF4CB050) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF4CB050).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isSelected 
                      ? const Color(0xFF4CB050)
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? const Color(0xFF4CB050)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF4CB050),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/onboarding_images/fllogo.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get('select_role'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CB050),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('role_description'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Role Options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRoleCard(
                      UserRole.farmer,
                      l10n.get('farmer'),
                      l10n.get('farmer_description'),
                      Icons.agriculture,
                    ),
                    _buildRoleCard(
                      UserRole.consumer,
                      l10n.get('consumer'),
                      l10n.get('consumer_description'),
                      Icons.shopping_cart,
                    ),
                    _buildRoleCard(
                      UserRole.foodDistributor,
                      l10n.get('food_distributor'),
                      l10n.get('distributor_description'),
                      Icons.store,
                    ),
                    _buildRoleCard(
                      UserRole.transporter,
                      l10n.get('transporter'),
                      l10n.get('transporter_description'),
                      Icons.local_shipping,
                    ),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: (_selectedRole != null && !authProvider.isLoading) 
                        ? _continueWithRole 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CB050),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.get('continue'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
