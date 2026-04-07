import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.serial});
  final String serial;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.phone_android_rounded, size: 18),
      label: Text(serial),
      onPressed: () => Navigator.pushNamed(context, '/device/$serial'),
    );
  }
}