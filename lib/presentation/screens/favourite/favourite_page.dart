import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class FavouritePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
          title: Text("Favourite"), backgroundColor: AppColors.backgroundColor),
      body:
          Center(child: Text("Favourite Page", style: TextStyle(fontSize: 20))),
    );
  }
}
