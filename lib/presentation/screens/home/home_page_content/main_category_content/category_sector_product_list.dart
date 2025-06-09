import 'package:eqcart/presentation/screens/home/home_page_content/main_category_content/variants_product_bottomsheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../utils/colors.dart';
import '../../../cart/cart_page.dart';
import '../../cart_controller.dart';
import '../../view_cart_bar.dart';

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

    return Stack(
      children: [
        /// Product List
        StreamBuilder<List<DocumentSnapshot>>(
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
              padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: 80), // extra bottom padding
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 225,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final data = products[index].data() as Map<String, dynamic>;
                return _ProductGridCard(
                  product: data,
                  shopId: shopId,
                  categoryName: categoryName,
                );
              },
            );
          },
        ),

        /// ViewCartBar at Bottom
        Positioned(
          bottom: 10,
          left: 20,
          right: 20,
          child: Consumer<CartController>(
            builder: (context, cartController, child) {
              return ViewCartBar(
                totalItems: cartController.totalItems,
                totalPrice: cartController.totalPrice,
                onTap: () {
                  // Navigate to Cart Page or Cart Tab
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CartPage()), // adjust path
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductGridCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final String shopId;
  final String categoryName;

  const _ProductGridCard({
    required this.product,
    required this.shopId,
    required this.categoryName,
  });

  @override
  State<_ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<_ProductGridCard> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get hasAvailableVariant {
    final variants = widget.product['variants'] as List<dynamic>?;
    if (variants == null || variants.isEmpty) return false;

    return variants.any(
        (variant) => variant['stock']?.toString().toLowerCase() == 'instock');
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = product['variants'] as List<dynamic>?;
    final mainProductStock =
        product['stock']?.toString().toLowerCase() == 'instock';
    final isAvailable = mainProductStock || hasAvailableVariant;

    return Opacity(
      opacity:
          isAvailable ? 1.0 : 0.5, // Make it semi-transparent if out of stock
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: !isAvailable, // Disable taps if out of stock
            child: Container(
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
                  /// Product Image with overlays
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
                      if ((product['discount'] ?? 0) > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                    ],
                  ),

                  /// Product Info
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
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
                                    '${product['product_weight']}',
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
                          padding: const EdgeInsets.only(top: 15),
                          child: GestureDetector(
                            onTap: isAvailable
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                      ),
                                      builder: (_) => VariantBottomSheet(
                                        imageUrl: product['image_url'] ?? '',
                                        productName:
                                            product['product_name'] ?? '',
                                        variants: variants != null &&
                                                variants.isNotEmpty
                                            ? List<Map<String, dynamic>>.from(
                                                product['variants'] ?? [])
                                            : [],
                                        productWeight: product['product_weight']
                                                ?.toString() ??
                                            '',
                                        productPrice:
                                            product['product_price'].toInt(),
                                        productMRP: product['product_mrp'] ??
                                            product['product_price'].toInt(),
                                        discount: product['discount'].toInt(),
                                        userId: userId,
                                        productId: product['sku_id'],
                                        shopId: widget.shopId,
                                        categoryName: widget.categoryName,
                                        onCartUpdated: () {},
                                        productStock:
                                            product['stock']?.toString() ?? '0',
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? AppColors.secondaryColor
                                    : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: isAvailable
                                    ? Colors.white
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Out of Stock label overlay
          if (!isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Out of Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
