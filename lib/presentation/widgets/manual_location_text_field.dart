import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class ManualLocationTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const ManualLocationTextField(this.label, this.hint, this.controller,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor)),
          TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hint)),
        ],
      ),
    );
  }
}
