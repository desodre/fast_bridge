import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.serial});
  final String serial;


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black),
      child: Text(serial, style: .new(color: Colors.black)),
      onPressed: () {
      Navigator.pushNamed(context, '/device/$serial');
    
    });
  }
}