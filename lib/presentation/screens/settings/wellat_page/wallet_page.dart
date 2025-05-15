import 'package:eqcart/presentation/screens/settings/wellat_page/wallet_service.dart';
import 'package:flutter/material.dart';

import 'add_money_page.dart';
import '../../../../utils/colors.dart';

class WalletPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('My Wallet'),
        backgroundColor: AppColors.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<double>(
          stream: WalletService.walletBalanceStream(),
          builder: (context, snapshot) {
            double balance = snapshot.data ?? 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Text('Wallet Balance',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 36,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AddMoneyPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text('Add Money', style: TextStyle(fontSize: 18)),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // later i Implement Transaction History
                  },
                  child: Text('View Transaction History',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
