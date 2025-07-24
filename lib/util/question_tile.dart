import 'package:flutter/material.dart';

class QuestionTile extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final int? selectedOptionIndex; // The index of the selected option
  final ValueChanged<int?>? onOptionSelected; // Callback for option selection
  const QuestionTile({
    super.key,
    required this.questionText,
    required this.options,
    this.selectedOptionIndex,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questionText,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.0,
              ),
            ),
            // Options
            Column(
              children: List.generate(options.length, (index) {
                return Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: selectedOptionIndex,
                      onChanged: onOptionSelected,
                      activeColor: Color(0xFF078798),
                    ),
                    Expanded(
                      child: Text(
                        options[index],
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

