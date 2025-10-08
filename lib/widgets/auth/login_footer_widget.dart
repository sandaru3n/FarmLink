import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmlink/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/dashboards/dashboard_router.dart';
import '../../utils/app_localizations.dart';

class LoginFooterWidget extends StatelessWidget {
  const LoginFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("OR"),
        
        const SizedBox(height: TConstants.formHeight - 20),
        
        // Google Sign In Button
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Image(
                  image: AssetImage(TConstants.googleLogoImage), 
                  width: 20.0,
                ),
                onPressed: authProvider.isLoading ? null : () => _performGoogleSignIn(context, authProvider),
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
        
        // Sign Up Prompt
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          },
          child: Text.rich(
            TextSpan(
              text: TConstants.dontHaveAnAccount,
              style: Theme.of(context).textTheme.bodyLarge,
              children: const [
                TextSpan(
                  text: TConstants.signup, 
                  style: TextStyle(
                    color: Color(0xFF4CB050),
                    fontWeight: FontWeight.w600,
                  )
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
      // Login page: Only allow users who already have a role
      if (authProvider.currentRole == null) {
        // User doesn't have a role yet - they need to sign up first
        await authProvider.signOut(); // Sign them out
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('No account found. Please sign up first.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // User has a role, proceed to dashboard
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
