import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/colors.dart';

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Cached Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item['image_url'] ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['product_name'] ?? '').toString().length > 25
                        ? '${item['product_name'].toString().substring(0, 25)}...'
                        : item['product_name'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['variant_weight'] ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${(item['price'] ?? 0) * (item['quantity'] ?? 1)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            /// Quantity Selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 0),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 14),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 10, minHeight: 10),
                    onPressed: () => onQuantityChanged(item['quantity'] - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${item['quantity']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 14),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 10, minHeight: 10),
                    onPressed: () => onQuantityChanged(item['quantity'] + 1),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
