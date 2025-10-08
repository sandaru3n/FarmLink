import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmlink/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/dashboards/dashboard_router.dart';

class SignupFooterWidget extends StatelessWidget {
  const SignupFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("OR"),
        
        const SizedBox(height: TConstants.formHeight - 20),
        
        // Google Sign In Button
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: authProvider.isLoading ? null : () => _performGoogleSignIn(context, authProvider),
            icon: const Image(
              image: AssetImage(TConstants.googleLogoImage),
              width: 20.0,
            ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.grey, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                label: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        TConstants.signInWithGoogle.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
              ),
            );
          },
        ),
        
        const SizedBox(height: TConstants.formHeight - 20),
        
        // Login Prompt
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: TConstants.alreadyHaveAnAccount,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                TextSpan(
                  text: TConstants.loginText.toUpperCase(),
                  style: const TextStyle(color: Colors.blue)
                )
              ]
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _performGoogleSignIn(BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.signInWithGoogle();

    if (success && context.mounted) {
      // Check if user has a role, if not navigate to role selection
      if (authProvider.currentRole == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardRouter(),
          ),
          (route) => false,
        );
      }
    } else if (!success && context.mounted && authProvider.error != null) {
      // Show error as snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(authProvider.error!),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
