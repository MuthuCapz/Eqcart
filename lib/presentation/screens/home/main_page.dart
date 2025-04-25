import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../utils/colors.dart';
import '../cart/cart_page.dart';
import '../favourite/favourite_page.dart';
import '../settings/settings_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int totalItems = 0;
  double totalPrice = 0.0;

  final Widget _homeScreen = HomeScreen();

  @override
  void initState() {
    super.initState();
    _listenToCartChanges();
  }

  void _listenToCartChanges() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('cart')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      int items = 0;
      double price = 0.0;

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          data.forEach((productId, productList) {
            if (productList is List) {
              for (var item in productList) {
                final qty = (item['quantity'] ?? 1);
                final itemPrice = (item['price'] ?? 0.0);

                final quantity = (qty is int) ? qty : (qty as num).toInt();
                final priceValue = (itemPrice is double)
                    ? itemPrice
                    : (itemPrice as num).toDouble();

                items += quantity;
                price += priceValue * quantity;
              }
            }
          });
        }
      }

      setState(() {
        totalItems = items;
        totalPrice = price;
      });
    });
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _homeScreen,
            if (totalItems > 0)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => _navigateTo(context, CartPage()),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$totalItems Items | ₹${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'View Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Cart',
                onTap: () => _navigateTo(context, CartPage()),
              ),
              _buildNavItem(
                icon: Icons.favorite_border,
                label: 'Favourite',
                onTap: () => _navigateTo(context, FavouritePage()),
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => _navigateTo(context, SettingsPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.secondaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.grey,
                ),
                if (selected)
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
