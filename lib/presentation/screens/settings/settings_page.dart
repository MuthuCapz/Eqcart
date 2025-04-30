import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'wallet_page.dart'; // <-- Import wallet page

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: AppColors.backgroundColor,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.account_balance_wallet),
            title: Text('Wallet'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletPage()),
              );
            },
          ),
          Divider(),
          SizedBox(height: 250),
          Center(
            child: Text(
              "Settings Page",
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
