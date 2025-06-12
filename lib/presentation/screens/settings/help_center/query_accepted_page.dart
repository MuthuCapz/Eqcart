import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

class QueryAcceptedPage extends StatefulWidget {
  const QueryAcceptedPage({super.key});

  @override
  State<QueryAcceptedPage> createState() => _QueryAcceptedPageState();
}

class _QueryAcceptedPageState extends State<QueryAcceptedPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop(); // Go back to the previous page after 5s
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(24),
          elevation: 8,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    color: AppColors.primaryColor, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Query Submitted Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thank you for reaching out. You’ll hear from us within 24–28 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
