// lib/controllers/cart_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CartController extends ChangeNotifier {
  int totalItems = 0;
  double totalPrice = 0.0;

  CartController() {
    _listenToCart();
  }
  void _listenToCart() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('cart')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      int items = 0;
      double price = 0.0;

      final data = snapshot.data();
      if (data != null) {
        for (var productList in data.values) {
          if (productList is List) {
            for (var item in productList) {
              final qty = (item['quantity'] ?? 1) as int;
              final itemPrice = (item['price'] ?? 0.0) as num;

              items += qty;
              price += itemPrice.toDouble() * qty;
            }
          }
        }
      }

      totalItems = items;
      totalPrice =
          double.parse(price.toStringAsFixed(2)); // Optional: round off
      notifyListeners();
    });
  }
}
