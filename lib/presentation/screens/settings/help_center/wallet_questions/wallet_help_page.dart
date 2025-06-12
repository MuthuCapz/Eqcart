import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../custom_query_page.dart';
import '../help_page_widget.dart';

class WalletHelpPage extends StatelessWidget {
  const WalletHelpPage({Key? key}) : super(key: key);

  static const walletOptions = [
    'Wallet balance issue',
    'Transfer balance to another account',
    'Top-up Eqcart Wallet problems',
    'Withdraw Eqcart Wallet balance',
    'It\'s something else',
  ];

  @override
  Widget build(BuildContext context) {
    return HelpOptionsPage(
      title: 'Wallet Inquiries',
      options: walletOptions,
      onOptionTap: (index) {
        switch (index) {
          case 0:
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CustomQueryPage(category: 'Wallet Inquiries'),
              ),
            );
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped: ${walletOptions[index]}')),
            );
        }
      },
    );
  }
}
