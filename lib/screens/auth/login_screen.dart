import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../widgets/auth/login_header_widget.dart';
import '../../widgets/auth/login_form_widget.dart';
import '../../widgets/auth/login_footer_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(TConstants.defaultSize),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoginHeaderWidget(),
                LoginFormWidget(),
                LoginFooterWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
