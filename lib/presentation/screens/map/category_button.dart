import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? selectedType;
  final Function(String) onSelect;

  const CategoryButton(this.icon, this.label, this.selectedType, this.onSelect,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onSelect(label),
      icon: Icon(icon, color: AppColors.primaryColor),
      label: Text(label),
    );
  }
}
