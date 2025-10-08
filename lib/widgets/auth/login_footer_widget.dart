import 'package:flutter/material.dart';
import 'package:farmlink/constants/app_constants.dart';
import '../../screens/auth/signup_screen.dart';
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Image(
              image: AssetImage(TConstants.googleLogoImage), 
              width: 20.0,
            ),
            onPressed: () {
              // Add Google sign-in functionality
            },
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
            label: const Text(
              TConstants.signInWithGoogle,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: TConstants.formHeight - 20),
        
        // Sign Up Prompt
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const SignUpScreen(),
              ),
            );
          },
          child: Text.rich(
            TextSpan(
              text: TConstants.dontHaveAnAccount,
              style: Theme.of(context).textTheme.bodyLarge,
              children: const [
                TextSpan(
                  text: TConstants.signup, 
                  style: TextStyle(color: Colors.blue)
                )
              ]
            ),
          ),
        ),
      ],
    );
  }
}
