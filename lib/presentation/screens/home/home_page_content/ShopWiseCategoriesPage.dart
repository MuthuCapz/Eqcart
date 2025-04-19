import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../utils/colors.dart';
import 'category_sector_product_list.dart';
import 'category_selector.dart';

class ShopCategoriesPage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopCategoriesPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopCategoriesPage> createState() => _ShopCategoriesPageState();
}

class _ShopCategoriesPageState extends State<ShopCategoriesPage> {
  int selectedCategoryIndex = 0;

  Stream<List<Map<String, dynamic>>> getShopCategoriesStream(String shopId) {
    final shopsCategoriesRef =
        FirebaseFirestore.instance.collection('shops_categories').doc(shopId);
    final ownShopsCategoriesRef = FirebaseFirestore.instance
        .collection('own_shops_categories')
        .doc(shopId);

    return Rx.combineLatest2(
      shopsCategoriesRef.snapshots(),
      ownShopsCategoriesRef.snapshots(),
      (shopSnap, ownShopSnap) {
        final List<dynamic> categories =
            (shopSnap.exists ? shopSnap['categories'] ?? [] : []) +
                (ownShopSnap.exists ? ownShopSnap['categories'] ?? [] : []);
        return categories
            .map<Map<String, dynamic>>((item) => {
                  'category_name': item['category_name'],
                  'image_url': item['image_url'],
                })
            .toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(widget.shopName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getShopCategoriesStream(widget.shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text("No categories found."));
          }

          final selectedCategory =
              categories[selectedCategoryIndex]['category_name'];

          return Column(
            children: [
              const SizedBox(height: 10),
              CategorySelector(
                categories: categories,
                selectedIndex: selectedCategoryIndex,
                onCategorySelected: (index) {
                  setState(() => selectedCategoryIndex = index);
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ProductListView(
                    shopId: widget.shopId,
                    categoryName: selectedCategory,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
