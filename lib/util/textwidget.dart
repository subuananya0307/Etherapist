import 'package:flutter/material.dart';

class Textwidget extends StatelessWidget {
  final controller;
  final String hintText;
  final bool hiddenText;

  const Textwidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.hiddenText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: TextField(
          controller: controller,
          obscureText: hiddenText,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
          ),
        ),
      ),
    ),);
  }
}
