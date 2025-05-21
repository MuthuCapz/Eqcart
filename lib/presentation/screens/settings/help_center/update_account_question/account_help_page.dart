import 'package:eqcart/presentation/screens/settings/Delete_account/delete_account_page.dart';

import 'package:flutter/material.dart';

import '../help_page_widget.dart';

class AccountHelpPage extends StatelessWidget {
  const AccountHelpPage({Key? key}) : super(key: key);

  static const accountOptions = [
    'Change contact details',
    'Deactivate my account',
    'Delete My Account',
    'Add new address',
    'It\'s something else',
  ];

  @override
  Widget build(BuildContext context) {
    return HelpOptionsPage(
      title: 'Update Account',
      options: accountOptions,
      onOptionTap: (index) {
        switch (index) {
          case 1: // Deactivate my account
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeleteAccountPage(),
              ),
            );
            break;
          case 2: // Delete My Account
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeleteAccountPage(),
              ),
            );
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped: ${accountOptions[index]}')),
            );
        }
      },
    );
  }
}
