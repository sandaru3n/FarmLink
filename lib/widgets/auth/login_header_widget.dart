import 'package:flutter/material.dart';
import 'package:farmlink/constants/app_constants.dart';

class LoginHeaderWidget extends StatelessWidget {
  const LoginHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image(
            image: const AssetImage(TConstants.welcomeScreenImage),
            height: size.height * 0.2,
            width: size.width * 0.7,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          TConstants.loginTitle, 
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
        Text(
          TConstants.loginSubTitle, 
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.left,
        ),
      ],
    );
  }
}
