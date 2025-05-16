import 'package:flutter/cupertino.dart';

import '../help_page_widget.dart';

class WalletHelpPage extends StatelessWidget {
  const WalletHelpPage({Key? key}) : super(key: key);

  static const walletOptions = [
    'Wallet balance issue',
    'Transfer balance to another account',
    'Top-up Snoonu Wallet problems',
    'Withdraw Snoonu Wallet balance',
    'It\'s something else',
  ];

  @override
  Widget build(BuildContext context) {
    return const HelpOptionsPage(
      title: 'Wallet Inquiries',
      options: walletOptions,
    );
  }
}
