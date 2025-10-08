import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../widgets/auth/form_header_widget.dart';
import '../../widgets/auth/signup_form_widget.dart';
import '../../widgets/auth/signup_footer_widget.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(TConstants.defaultSize),
            child: const Column(
              children: [
                SizedBox(height: 0), // Top spacing
                FormHeaderWidget(
                  image: TConstants.welcomeScreenImage,
                  title: TConstants.signUpTitle,
                  subTitle: TConstants.signUpSubTitle,
                  imageHeight: 0.07,
                  heightBetween: 60,
                ),
                SignUpFormWidget(),
                SignupFooterWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
