import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../custom_query_page.dart';
import '../help_page_widget.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  static const feedbackOptions = [
    'Not happy with Merchant behavior',
    'Not happy with Rider behavior',
    'I am not happy with Customer Support',
    'Feedback & Suggestion',
    'It\'s something else',
  ];

  @override
  Widget build(BuildContext context) {
    return HelpOptionsPage(
      title: 'Feedback & Complaints',
      options: feedbackOptions,
      onOptionTap: (index) {
        switch (index) {
          case 0:
            break;
          case 4: // Delete My Account
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CustomQueryPage(category: 'FeedBack Queries'),
              ),
            );
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped: ${feedbackOptions[index]}')),
            );
        }
      },
    );
  }
}
