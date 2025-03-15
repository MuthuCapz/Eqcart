import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

Widget buildProfileField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    ),
  );
}

Widget buildProfilePicture(String? profilePicUrl, VoidCallback onTap) {
  return Center(
    child: Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
              ? NetworkImage(profilePicUrl)
              : null,
          child: profilePicUrl == null || profilePicUrl.isEmpty
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onTap,
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white,
              child: Icon(Icons.edit, size: 18, color: AppColors.primaryColor),
            ),
          ),
        ),
      ],
    ),
  );
}
