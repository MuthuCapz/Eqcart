import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../utils/colors.dart';

class CategorySelector extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: isSelected ? 32 : 28,
                  backgroundColor: isSelected
                      ? AppColors.secondaryColor
                      : Colors.grey.shade300,
                  backgroundImage:
                      CachedNetworkImageProvider(category['image_url']),
                ),
                const SizedBox(height: 6),
                Text(
                  category['category_name'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected ? AppColors.secondaryColor : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
