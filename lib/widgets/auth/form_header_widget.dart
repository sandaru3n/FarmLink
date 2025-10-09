import 'package:flutter/material.dart';

class FormHeaderWidget extends StatelessWidget {
  const FormHeaderWidget({
    Key? key,
    this.imageColor,
    this.heightBetween,
    required this.image,
    required this.title,
    required this.subTitle,
    this.imageHeight = 0.2,
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  final Color? imageColor;
  final double imageHeight;
  final double? heightBetween;
  final String image, title, subTitle;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Center(
          child: Image(
            image: AssetImage(image), 
            color: imageColor, 
            height: size.height * imageHeight,
          ),
        ),
        SizedBox(height: heightBetween ?? 16),
        Text(
          title, 
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: textAlign ?? TextAlign.left,
        ),
        const SizedBox(height: 8),
        Text(
          subTitle, 
          textAlign: textAlign, 
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
