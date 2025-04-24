import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'product_add_button_function.dart';

class VariantBottomSheet extends StatelessWidget {
  final String productName;
  final String imageUrl;
  final List<Map<String, dynamic>> variants;
  final String productWeight;
  final int productPrice;
  final int productMRP;
  final int discount;
  final String userId;
  final String productId;
  final VoidCallback onCartUpdated;

  const VariantBottomSheet({
    super.key,
    required this.productName,
    required this.imageUrl,
    required this.variants,
    required this.productWeight,
    required this.productPrice,
    required this.productMRP,
    required this.discount,
    required this.userId,
    required this.productId,
    required this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Title
            Center(
              child: Text(
                productName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Main product
            _buildVariantTile(
              volume: productWeight,
              price: productPrice,
              mrp: productMRP,
              discount: discount,
            ),

            // Variant List
            ListView.builder(
              itemCount: variants.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final variant = variants[index];
                final price = (variant['price'] as num).toInt();
                final mrp = (variant['mrp'] as num?)?.toInt() ?? 0;
                final volume = variant['volume']?.toString() ?? '';
                final discount = (mrp > price && mrp != 0)
                    ? ((mrp - price) * 100 ~/ mrp)
                    : 0;

                return _buildVariantTile(
                  volume: volume,
                  price: price,
                  mrp: mrp,
                  discount: discount,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantTile({
    required String volume,
    required int price,
    required int mrp,
    required int discount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image - cached
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 55,
                height: 55,
                color: Colors.grey[200],
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(width: 16),

          // Center content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatWeight(volume),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₹$price',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    if (mrp > price)
                      Text('₹$mrp',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 6),
                    if (discount > 0)
                      Text('$discount% OFF',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),

          // Add/Qty button
          AddToCartButtons(
            userId: userId,
            productId: productId,
            productName: productName,
            price: price.toDouble(),
            imageUrl: imageUrl,
            variantKey: productWeight,
            variantWeight: volume,
            onCartUpdated: onCartUpdated,
          ),
        ],
      ),
    );
  }
}

String _formatWeight(String volume) {
  // Lowercase check for units
  final lower = volume.toLowerCase();

  // If it already contains units like 'kg', 'g', 'ml', 'l', etc., return as is
  if (lower.contains('kg') ||
      lower.contains('g') ||
      lower.contains('ml') ||
      lower.contains('lit') ||
      lower.contains('ltr') ||
      lower.contains('pcs') ||
      lower.contains('piece')) {
    return volume;
  }

  // Else, assume 'kg' is missing
  return '$volume kg';
}
