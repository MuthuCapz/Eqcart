import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../utils/colors.dart';
import '../banner_carousel.dart';
import '../nearest_shops/matched_shops_page.dart';
import 'main_category_shops_page.dart';

class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final ValueNotifier<List<Map<String, dynamic>>> _categoriesNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([
    {
      "category_name": "Milk",
      "category_offer": "Loading",
      "image_url": "https://via.placeholder.com/100"
    },
    {
      "category_name": "Grocery",
      "category_offer": "Loading",
      "image_url": "https://via.placeholder.com/100"
    },
    {
      "category_name": "Snacks",
      "category_offer": "Loading",
      "image_url": "https://via.placeholder.com/100"
    },
  ]);

  @override
  void initState() {
    super.initState();
    _listenToCategories();
  }

  void _listenToCategories() {
    FirebaseFirestore.instance
        .collection('main_categories')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final categories = data['categories'];
        if (categories != null && categories is List) {
          _categoriesNotifier.value =
              List<Map<String, dynamic>>.from(categories);
        }
      }
    });
  }

  Widget _buildCategoryList() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _categoriesNotifier,
      builder: (context, categories, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final categoryName = category["category_name"] ?? '';
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryShopsPage(
                            categoryName: categoryName,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      8), // Rounded square
                                  border: Border.all(
                                    color: AppColors
                                        .secondaryColor, // Change to your desired border color
                                    width: 1, // Border thickness
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    category["image_url"] ?? "",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (category["category_offer"] != null &&
                                  category["category_offer"]
                                      .toString()
                                      .isNotEmpty)
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category["category_offer"],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            categoryName,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BannerCarousel(),
            SizedBox(height: 20),
            _buildCategoryList(),
            SizedBox(height: 20),
            MatchedShopsPage(),
            SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
