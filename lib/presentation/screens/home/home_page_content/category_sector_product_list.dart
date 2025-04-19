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

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            return _ProductCard(product: data);
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final variants = product['variants'] as List<dynamic>?;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Product Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product['image_url'] ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const CircularProgressIndicator(strokeWidth: 2),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['product_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product['product_weight'] != null)
                        Text(
                          '${product['product_weight']} kg',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      Text(
                        '₹${(product['product_price'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      if ((product['discount'] ?? 0) > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product['discount']}% OFF',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (variants != null && variants.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                    onPressed: () {
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
                    },
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (product['description'] != null)
              Text(
                product['description'],
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
          ],
        ),
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
