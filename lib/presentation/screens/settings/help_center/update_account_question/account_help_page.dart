import 'package:eqcart/presentation/screens/settings/Delete_account/delete_account_page.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../map/current_location_update.dart';
import '../../../map/google_map_screen.dart';
import '../custom_query_page.dart';
import '../help_page_widget.dart';

class AccountHelpPage extends StatelessWidget {
  const AccountHelpPage({Key? key}) : super(key: key);

  static const accountOptions = [
    'Change contact details',
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
          case 0:
            break;
          case 1: // Delete My Account
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeleteAccountPage(),
              ),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (_) => LocationProvider()..getUserLocation(),
                  child: GoogleMapScreen(
                    label: '',
                  ),
                ),
              ),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CustomQueryPage(category: 'Accounts Inquiries'),
              ),
            );
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped: ${accountOptions[index]}')),
            );
        }
      },
    );
  }
}
