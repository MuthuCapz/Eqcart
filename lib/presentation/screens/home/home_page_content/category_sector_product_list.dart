import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../utils/colors.dart';

class ProductListView extends StatelessWidget {
  final String shopId;
  final String categoryName;

  const ProductListView({
    super.key,
    required this.shopId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProductsRef = FirebaseFirestore.instance
        .collection('shops_products')
        .doc(shopId)
        .collection(categoryName);

    final ownCategoryProductsRef = FirebaseFirestore.instance
        .collection('own_shops_products')
        .doc(shopId)
        .collection(categoryName);

    final combinedStream =
        Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<DocumentSnapshot>>(
      categoryProductsRef.snapshots(),
      ownCategoryProductsRef.snapshots(),
      (snap1, snap2) => [...snap1.docs, ...snap2.docs],
    );

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: combinedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(child: Text("No products found."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 225,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            return _ProductGridCard(product: data);
          },
        );
      },
    );
  }
}

class _ProductGridCard extends StatefulWidget {
  final Map<String, dynamic> product;

  const _ProductGridCard({required this.product});

  @override
  State<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<_ProductGridCard> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = product['variants'] as List<dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor,
          width: 0.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Product Image with Overlays
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: product['image_url'] ?? '',
                  height: 125,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined, size: 50),
                ),
              ),

              /// Offer Badge - Top Left
              if ((product['discount'] ?? 0) > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product['discount']}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              /// Add Icon - Top Right
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    /// Favorite Icon
                    GestureDetector(
                      onTap: () => setState(() => isFavorite = !isFavorite),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 14,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// Product Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['product_name'] ?? 'No Name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product['product_weight'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${product['product_weight']} kg',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${(product['product_price'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E5128),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Add Icon
                Padding(
                  padding:
                      const EdgeInsets.only(top: 15), // Move it down slightly
                  child: GestureDetector(
                    onTap: () {
                      // Show the VariantBottomSheet regardless of variants
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => VariantBottomSheet(
                          imageUrl: product['image_url'] ?? '',
                          productName: product['product_name'] ?? '',
                          variants: variants != null && variants.isNotEmpty
                              ? List<Map<String, dynamic>>.from(
                                  product['variants'] ?? [])
                              : [],
                          productWeight:
                              product['product_weight']?.toString() ?? '',
                          productPrice: product['product_price'].toInt(),
                          productMRP: product['product_mrp'] ??
                              product['product_price'].toInt(),
                          discount: product['discount'].toInt(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor, // Background
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryColor, // Stroke
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white, // Symbol
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VariantBottomSheet extends StatelessWidget {
  final String productName;
  final String imageUrl;
  final List<Map<String, dynamic>> variants;
  final String productWeight;
  final int productPrice;
  final int productMRP;
  final int discount;

  const VariantBottomSheet({
    super.key,
    required this.productName,
    required this.imageUrl,
    required this.variants,
    required this.productWeight,
    required this.productPrice,
    required this.productMRP,
    required this.discount,
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
          _AddToCartButton(),
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

// Dummy button UI
class _AddToCartButton extends StatefulWidget {
  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  int quantity = 0;

  @override
  Widget build(BuildContext context) {
    return quantity == 0
        ? ElevatedButton(
            onPressed: () {
              setState(() {
                quantity = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "Add",
              style: TextStyle(color: Colors.white),
            ),
          )
        : Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (quantity > 0) quantity--;
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$quantity', style: const TextStyle(fontSize: 16)),
              IconButton(
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          );
  }
}
