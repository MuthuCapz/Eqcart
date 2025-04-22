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
            mainAxisExtent: 180,
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
  int quantity = 0;
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
                  height: 90,
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
                    /// Favorite Icon below Add Button
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      if (variants != null && variants.isNotEmpty) {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => VariantBottomSheet(
                            imageUrl: product['image_url'],
                            productName: product['product_name'] ?? '',
                            variants: List<Map<String, dynamic>>.from(
                                product['variants'] ?? []),
                          ),
                        );
                      } else {
                        setState(
                            () => quantity == 0 ? quantity = 1 : quantity++);
                      }
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

class VariantBottomSheet extends StatefulWidget {
  final String productName;
  final String imageUrl;
  final List<Map<String, dynamic>> variants;

  const VariantBottomSheet({
    super.key,
    required this.productName,
    required this.imageUrl,
    required this.variants,
  });

  @override
  State<VariantBottomSheet> createState() => _VariantBottomSheetState();
}

class _VariantBottomSheetState extends State<VariantBottomSheet> {
  Map<int, int> cartCounts = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(widget.variants.length, (index) {
            final variant = widget.variants[index];
            final volume = variant['volume'] ?? '';
            final price = variant['price'] ?? 0;
            final mrp = variant['mrp'] ?? 0;
            final discount = mrp > price ? ((mrp - price) * 100 ~/ mrp) : 0;
            final count = cartCounts[index] ?? 0;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  /// Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.image, size: 50),
                    ),
                  ),

                  const SizedBox(width: 25),

                  /// Center Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (discount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$discount% OFF',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.deepOrange),
                            ),
                          ),
                        Text(
                          '$volume',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              '₹$price',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            const SizedBox(width: 6),
                            if (discount > 0)
                              Text(
                                '₹$mrp',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// Right Add/Counter
                  count == 0
                      ? ElevatedButton(
                          onPressed: () {
                            setState(() {
                              cartCounts[index] = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            foregroundColor: Colors.white,
                            side:
                                const BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text('ADD'),
                        )
                      : Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (cartCounts[index]! > 1) {
                                    cartCounts[index] = cartCounts[index]! - 1;
                                  } else {
                                    cartCounts.remove(index);
                                  }
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${cartCounts[index]}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  cartCounts[index] = cartCounts[index]! + 1;
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
