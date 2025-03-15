import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final bool isPasswordField;
  final String? Function(String?)? validator;
  final VoidCallback? onTogglePassword; // For toggling password visibility
  final bool isPasswordVisible; // State for password visibility

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.isPasswordField = false,
    this.validator,
    this.onTogglePassword,
    this.isPasswordVisible = false, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(30),
      child: TextFormField(
        controller: controller,
        obscureText: isPasswordField
            ? !isPasswordVisible
            : obscureText, // Toggle visibility
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.grey[500]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppColors.secondaryColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
          ),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: onTogglePassword, // Call toggle function
                )
              : null,
        ),
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
