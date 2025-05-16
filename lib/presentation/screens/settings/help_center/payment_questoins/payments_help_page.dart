import 'package:flutter/cupertino.dart';

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
    return const HelpOptionsPage(
      title: 'Questions about Payments',
      options: paymentHelpOptions,
    );
  }
}
