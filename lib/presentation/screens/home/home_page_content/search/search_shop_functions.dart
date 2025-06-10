import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchShopController {
  final BuildContext context;
  final VoidCallback onUpdate;

  List<Map<String, dynamic>> allShops = [];
  List<Map<String, dynamic>> filteredShops = [];
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  bool isLoading = true;
  bool isSearching = false;

  Timer? _debounce;
  Map<String, List<String>> shopCategoryCache = {};

  SearchShopController(this.context, this.onUpdate);

  void init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocus);
    });
    searchController.addListener(_debounceFilterShops);
    fetchMatchedShops();
  }

  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    searchFocus.dispose();
  }

  void _debounceFilterShops() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 100), () {
      filterShops();
    });
  }

  void filterShops() async {
    String query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      filteredShops = allShops;
      isSearching = false;
      onUpdate();
      return;
    }

    isSearching = true;
    onUpdate();

    List<Map<String, dynamic>> matchedShops = [];

    for (var shop in allShops) {
      // allShops only contains isActive: true shops
      final String? shopName = shop['shop_name']?.toLowerCase();
      final String shopId = shop['shop_id'];

      if (shopName != null && shopName.contains(query)) {
        matchedShops.add(shop);
        continue;
      }

      final bool found = await hasMatchingProduct(shopId, query);
      if (found) {
        matchedShops.add(shop);
      }
    }

    filteredShops = matchedShops;
    isSearching = false;
    onUpdate();
  }

  void runSearch() {
    final query = searchController.text.trim().toLowerCase();
    isSearching = true;
    onUpdate();

    Future.delayed(Duration(milliseconds: 300), () {
      filteredShops = allShops.where((shop) {
        final name = (shop['shop_name'] ?? '').toString().toLowerCase();
        final city = (shop['city'] ?? '').toString().toLowerCase();
        return name.contains(query) || city.contains(query);
      }).toList();

      isSearching = false;
      onUpdate();
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

    List<Future<Map<String, dynamic>?>> shopFutures =
        matchedIds.map((id) async {
      for (String collection in ['shops', 'own_shops']) {
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(id)
            .get();
        if (doc.exists) {
          final shop = doc.data()!;
          return {
            'shop_id': id,
            'shop_name': shop['shop_name'] ?? '',
            'shop_logo': shop['shop_logo'] ?? '',
            'description': shop['description'] ?? '',
            'city': shop['location']?['city'] ?? '',
            'isActive': shop['isActive'] ?? false,
          };
        }
      }
      return null;
    }).toList();

    final results = await Future.wait(shopFutures);
    final shopsList = results
        .whereType<Map<String, dynamic>>()
        .where((shop) => shop['isActive'] == true) //  Filter out inactive shops
        .toList();

    allShops = shopsList;
    filteredShops = shopsList;
    isLoading = false;
    onUpdate();
  }

  Future<List<String>> getCategoryNames(String shopId) async {
    if (shopCategoryCache.containsKey(shopId)) {
      return shopCategoryCache[shopId]!;
    }

    List<String> categoryNames = [];

    for (String categoryCollection in [
      'shops_categories',
      'own_shops_categories'
    ]) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(categoryCollection)
          .doc(shopId)
          .get();

      if (docSnapshot.exists && docSnapshot.data()!.containsKey('categories')) {
        final List<dynamic> categoryArray = docSnapshot.data()!['categories'];
        for (var categoryMap in categoryArray) {
          if (categoryMap is Map && categoryMap.containsKey('category_name')) {
            final name = categoryMap['category_name'];
            if (name is String && name.trim().isNotEmpty) {
              categoryNames.add(name);
            }
          }
        }
      }
    }

    shopCategoryCache[shopId] = categoryNames;
    return categoryNames;
  }

  Future<bool> hasMatchingProduct(String shopId, String query) async {
    final lowerQuery = query.toLowerCase();

    try {
      for (String productCollection in [
        'shops_products',
        'own_shops_products'
      ]) {
        final categoryNames = await getCategoryNames(shopId);
        if (categoryNames.isEmpty) continue;

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

            if (querySnapshot.docs.isNotEmpty) return true;

            final fallbackSnapshot = await FirebaseFirestore.instance
                .collection(productCollection)
                .doc(shopId)
                .collection(category)
                .limit(10)
                .get();

            for (var doc in fallbackSnapshot.docs) {
              final productName =
                  (doc.data()['product_name'] ?? '').toString().toLowerCase();
              if (productName.contains(lowerQuery)) return true;
            }
          } catch (_) {}
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
