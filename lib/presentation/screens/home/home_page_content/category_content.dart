import 'package:flutter/material.dart';

import 'banner_carousel.dart';

class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
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

  Widget _buildCategoryList() {
    List<Map<String, dynamic>> categories = [
      {
        "name": "Milk",
        "icon": Icons.production_quantity_limits_outlined,
        "color": Colors.orange
      },
      {
        "name": "Clothing",
        "icon": Icons.production_quantity_limits,
        "color": Colors.green
      },
      {
        "name": "Grocery",
        "icon": Icons.production_quantity_limits_rounded,
        "color": Colors.blue
      },
      {
        "name": "Medicine",
        "icon": Icons.production_quantity_limits_sharp,
        "color": Colors.brown
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Category",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: categories.map((category) {
            return Column(
              children: [
                CircleAvatar(
                  backgroundColor: category["color"],
                  radius: 30,
                  child: Icon(category["icon"], color: Colors.white, size: 30),
                ),
                SizedBox(height: 5),
                Text(category["name"], style: TextStyle(fontSize: 14)),
              ],
            );
          }).toList(),
        ),
      ],
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
