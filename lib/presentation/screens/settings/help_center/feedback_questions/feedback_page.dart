import 'package:flutter/cupertino.dart';

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
    return const HelpOptionsPage(
      title: 'Feedback & Complaints',
      options: feedbackOptions,
    );
  }
}
