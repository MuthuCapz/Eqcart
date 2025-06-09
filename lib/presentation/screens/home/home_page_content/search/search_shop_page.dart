import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../../utils/colors.dart';
import '../main_category_content/ShopWiseCategoriesPage.dart';

class SearchShopPage extends StatefulWidget {
  @override
  _SearchShopPageState createState() => _SearchShopPageState();
}

class _SearchShopPageState extends State<SearchShopPage> {
  List<Map<String, dynamic>> allShops = [];
  List<Map<String, dynamic>> filteredShops = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  final FocusNode searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocus);
    });
    searchController.addListener(filterShops);
    fetchMatchedShops();
  }

  void filterShops() async {
    String query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => filteredShops = allShops);
      return;
    }

    List<Map<String, dynamic>> matchedShops = [];

    for (var shop in allShops) {
      String? shopName = shop['shop_name']?.toLowerCase();
      String shopId = shop['shop_id'];

      // 1. Check shop name match
      if (shopName != null && shopName.contains(query)) {
        matchedShops.add(shop);
        continue;
      }

      // 2. Check product name match

      bool found = await hasMatchingProduct(shopId, query);
      if (found) {
        matchedShops.add(shop);
      }
    }

    setState(() {
      filteredShops = matchedShops;
    });
  }

  Future<void> fetchMatchedShops() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final addressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .get();

    List<String> matchedIds = [];

    for (var doc in addressSnapshot.docs) {
      final data = doc.data();
      final manual = data['manual_location'];
      final map = data['map_location'];

      final isManualDefault = manual != null && manual['isDefault'] == true;
      final isMapDefault = map != null && map['isDefault'] == true;

      if (isManualDefault || isMapDefault) {
        matchedIds = List<String>.from(map?['matched_shop_ids'] ?? []);
        break;
      }
    }

    List<Map<String, dynamic>> shopsList = [];

    for (String id in matchedIds) {
      for (String collection in ['shops', 'own_shops']) {
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(id)
            .get();
        if (doc.exists) {
          final shop = doc.data()!;
          shopsList.add({
            'shop_id': id,
            'shop_name': shop['shop_name'] ?? '',
            'shop_logo': shop['shop_logo'] ?? '',
            'description': shop['description'] ?? '',
            'city': shop['location']?['city'] ?? '',
          });
          break;
        }
      }
    }

    setState(() {
      allShops = shopsList;
      filteredShops = shopsList;
      isLoading = false;
    });
  }

  Future<bool> hasMatchingProduct(String shopId, String query) async {
    final lowerQuery = query.toLowerCase();

    try {
      for (String productCollection in [
        'shops_products',
        'own_shops_products'
      ]) {
        // 1. Fetch categories dynamically from backend structure
        List<String> categoryNames = [];

        for (String categoryCollection in [
          'shops_categories',
          'own_shops_categories'
        ]) {
          final docSnapshot = await FirebaseFirestore.instance
              .collection(categoryCollection)
              .doc(shopId)
              .get();

          if (docSnapshot.exists &&
              docSnapshot.data()!.containsKey('categories')) {
            final List<dynamic> categoryArray =
                docSnapshot.data()!['categories'];
            for (var categoryMap in categoryArray) {
              if (categoryMap is Map &&
                  categoryMap.containsKey('category_name')) {
                final name = categoryMap['category_name'];
                if (name is String && name.trim().isNotEmpty) {
                  categoryNames.add(name);
                }
              }
            }
          }
        }

        if (categoryNames.isEmpty) {
          continue;
        }

        // 2. Search products in each category
        for (String category in categoryNames) {
          try {
            final querySnapshot = await FirebaseFirestore.instance
                .collection(productCollection)
                .doc(shopId)
                .collection(category)
                .where('product_name', isGreaterThanOrEqualTo: lowerQuery)
                .where('product_name',
                    isLessThanOrEqualTo: lowerQuery + '\uf8ff')
                .limit(1)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              return true;
            }

            final fallbackSnapshot = await FirebaseFirestore.instance
                .collection(productCollection)
                .doc(shopId)
                .collection(category)
                .limit(20)
                .get();

            for (var doc in fallbackSnapshot.docs) {
              final productName =
                  (doc.data()['product_name'] ?? '').toString().toLowerCase();
              if (productName.contains(lowerQuery)) {
                return true;
              }
            }
          } catch (e) {}
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Container(
          height: 45,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocus,
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: AppColors.primaryColor),
              hintText: 'Search food, groceries & more...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor))
          : filteredShops.isEmpty
              ? Center(
                  child: Text(
                    'No products and shops found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: filteredShops.length,
                  itemBuilder: (context, index) {
                    final shop = filteredShops[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(shop['shop_logo']),
                        ),
                        title: Text(
                          shop['shop_name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        subtitle: Text(
                          "${shop['city']} • ${shop['description']}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.secondaryColor, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopCategoriesPage(
                                shopId: shop['shop_id'],
                                shopName: shop['shop_name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
