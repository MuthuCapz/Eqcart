import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
          title: Text("Settings"), backgroundColor: AppColors.backgroundColor),
      body:
          Center(child: Text("Settings Page", style: TextStyle(fontSize: 20))),
    );
  }
}
