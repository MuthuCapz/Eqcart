import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
          title: Text("Cart"), backgroundColor: AppColors.backgroundColor),
      body: Center(child: Text("Cart Page", style: TextStyle(fontSize: 20))),
    );
  }
}
