import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'order_details_page.dart';

Widget buildProgressStep(String title, String currentStatus, int step) {
  final isCompleted = getStatusIndex(currentStatus) >= step;
  return Column(
    children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.secondaryColor : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : null,
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: TextStyle(
          fontSize: 10,
          color: isCompleted ? AppColors.secondaryColor : Colors.grey,
          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );
}

Widget buildOrderItem(Map<String, dynamic> item) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: item['imageUrl'] ?? '',
            height: 60,
            width: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 60,
              width: 60,
              color: Colors.grey[100],
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryColor)),
            ),
            errorWidget: (context, url, error) => Container(
              height: 60,
              width: 60,
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['productName'],
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text("${item['variantWeight']} × ${item['quantity']}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        Text(
          "₹${(item['price'] * item['quantity']).toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    ),
  );
}

Widget buildBillRow(String label, String value,
    {bool isBold = false, bool isTotal = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isTotal ? AppColors.primaryColor : Colors.grey[700],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 15 : 14)),
        Text(value,
            style: TextStyle(
                color: isTotal ? AppColors.primaryColor : Colors.grey[700],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 15 : 14)),
      ],
    ),
  );
}

// Helper functions
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'pending':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

int getStatusIndex(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 0;
    case 'preparing':
      return 1;
    case 'on the way':
      return 2;
    case 'delivered':
      return 3;
    case 'cancelled':
      return -1;
    default:
      return 0;
  }
}

double getStatusProgress(String status) {
  final index = getStatusIndex(status);
  if (index == -1) return 0; // Cancelled
  return (index + 1) / 4;
}
