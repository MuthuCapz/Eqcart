import 'package:flutter/cupertino.dart';

import '../help_page_widget.dart';

class AccountHelpPage extends StatelessWidget {
  const AccountHelpPage({Key? key}) : super(key: key);

  static const accountOptions = [
    'Change contact details',
    'Deactivate my account',
    'Add new address',
    'It\'s something else',
  ];

  @override
  Widget build(BuildContext context) {
    return const HelpOptionsPage(
      title: 'Update Account',
      options: accountOptions,
    );
  }
}
