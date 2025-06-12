import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../custom_query_page.dart';
import '../help_page_widget.dart';

class PaymentsHelpPage extends StatelessWidget {
  const PaymentsHelpPage({Key? key}) : super(key: key);

  static const paymentHelpOptions = [
    'I am unable to place an order',
    'Payment deducted but order not placed',
    'Issues with my preferred payment method',
    'OTP not received',
    'Promo code or voucher not working',
    'It\'s something else',
  ];

  @override
  Widget build(BuildContext context) {
    return HelpOptionsPage(
      title: 'Questions about Payments',
      options: paymentHelpOptions,
      onOptionTap: (index) {
        switch (index) {
          case 0:
            break;
          case 5: // Delete My Account
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CustomQueryPage(category: 'Payment Inquiries'),
              ),
            );
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped: ${paymentHelpOptions[index]}')),
            );
        }
      },
    );
  }
}
