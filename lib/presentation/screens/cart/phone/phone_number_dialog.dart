import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

Future<String?> showPhoneNumberDialog(BuildContext context) {
  final TextEditingController phoneController =
      TextEditingController(text: "+91");

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Verify Your Phone",
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: TextField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: AppColors.primaryColor),
        decoration: const InputDecoration(
          hintText: "+91xxxxxxxxxx",
          hintStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondaryColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel",
              style: TextStyle(color: AppColors.primaryColor)),
        ),
        ElevatedButton(
          onPressed: () {
            final number = phoneController.text.trim();
            if (number.isNotEmpty) {
              Navigator.pop(context, number);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child: const Text(
            "Submit",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
