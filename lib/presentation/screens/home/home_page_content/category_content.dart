import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'banner_carousel.dart';

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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage:
                                  NetworkImage(category["image_url"] ?? ""),
                              backgroundColor: Colors.grey[300],
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
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    category["category_offer"],
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          category["category_name"] ?? '',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
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
            _buildPopularService(),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularService() {
    List<Map<String, dynamic>> services = [
      {
        "title": "Fresh Milk",
        "subtitle": "Home made",
        "price": "₹468 / 1 lit",
        "rating": 4.7,
        "image": "assets/images/milk.jpg"
      },
      {
        "title": "Fresh Honey",
        "subtitle": "Sweet goleden honey",
        "price": "₹596 / 1 lit",
        "rating": 4.8,
        "image": "assets/images/honey.jpg"
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Top Selling",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: Text("See all")),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: services.map((service) {
            return Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.asset(service["image"],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover)),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service["title"],
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(service["subtitle"],
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(service["price"],
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  Text(service["rating"].toString(),
                                      style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
