import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  VoidCallback onPressed;

  MyButton({
    super.key,
    required this.text,
    required this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF078798), // Background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
        minimumSize: const Size(200, 50), // Minimum width and height
        padding: const EdgeInsets.symmetric(vertical: 16.0), // Padding inside the button
      ),
      child: Text(text,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.white,
      ),),
    );
  }
}
