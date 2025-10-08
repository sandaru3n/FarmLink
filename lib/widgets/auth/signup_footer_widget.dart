import 'package:flutter/material.dart';
import 'package:farmlink/constants/app_constants.dart';
import '../../screens/auth/login_screen.dart';

class SignupFooterWidget extends StatelessWidget {
  const SignupFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("OR"),
        
        const SizedBox(height: TConstants.formHeight - 20),
        
        // Google Sign In Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Add Google sign-in functionality
            },
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
            label: Text(
              TConstants.signInWithGoogle.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
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
}
