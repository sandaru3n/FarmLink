import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmlink/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_localizations.dart';
import '../../screens/dashboards/dashboard_router.dart';
import '../../screens/auth/forgot_password_screen.dart';

class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({Key? key}) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: TConstants.formHeight - 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_outlined),
                labelText: TConstants.email,
                hintText: TConstants.email,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.get('email_required');
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return l10n.get('invalid_email');
                }
                return null;
              },
            ),

            const SizedBox(height: TConstants.formHeight - 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.fingerprint),
                labelText: TConstants.password,
                hintText: TConstants.password,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.get('password_required');
                }
                return null;
              },
            ),

            const SizedBox(height: TConstants.formHeight - 20),

            // Forget Password Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  TConstants.forgetPassword,
                  style: TextStyle(
                    color: Color(0xFF4CB050),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: TConstants.formHeight - 10),

            // Login Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _performLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            TConstants.login.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DashboardRouter()),
        (route) => false,
      );
    } else if (!success && mounted && authProvider.error != null) {
      // Show error as snackbar popup with specific error message
      String errorMessage = authProvider.error!;
      
      // Customize error messages for better user experience
      if (errorMessage.toLowerCase().contains('password')) {
        errorMessage = 'Invalid password. Please try again.';
      } else if (errorMessage.toLowerCase().contains('user not found') || 
                 errorMessage.toLowerCase().contains('email')) {
        errorMessage = 'Invalid email address. Please check and try again.';
      } else if (errorMessage.toLowerCase().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (errorMessage == 'An error occurred') {
        errorMessage = 'Login failed. Please check your credentials.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(errorMessage),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
