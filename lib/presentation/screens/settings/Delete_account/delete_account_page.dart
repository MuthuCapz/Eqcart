import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../utils/colors.dart';
import '../../splash/splash_screen.dart';
import 'confirm_delete_dialog.dart';
import 'delete_account_functions.dart';

class DeleteAccountPage extends StatefulWidget {
  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.warning_amber_rounded,
                    color: AppColors.primaryColor, size: 60),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Are you absolutely sure?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This action will permanently delete your account and remove all associated data including wallet balance and reward points.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: AppColors.secondaryColor,
                    onChanged: (val) {
                      setState(() {
                        isChecked = val!;
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I understand this will remove my wallet balance and reward points.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'No, keep my account',
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AnimatedOpacity(
                opacity: isChecked ? 1 : 0.5,
                duration: Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: isChecked
                      ? () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;

                          final ordersSnapshot = await FirebaseFirestore
                              .instance
                              .collection('orders')
                              .doc(uid)
                              .collection('orders')
                              .get();

                          bool allDelivered = true;

                          for (var doc in ordersSnapshot.docs) {
                            final status = doc.data()['orderStatus'] ?? '';
                            if (status.toLowerCase() != 'delivered') {
                              allDelivered = false;
                              break;
                            }
                          }

                          if (!allDelivered) {
                            Fluttertoast.showToast(
                              msg:
                                  'Your orders are still in process and not delivered yet.\nOnce your order are delivered, you can delete your account.',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: AppColors.primaryColor,
                              textColor: Colors.white,
                              fontSize: 14,
                            );
                            return;
                          }

                          // All orders delivered → Show confirm dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => ConfirmDeleteDialog(),
                          );

                          if (confirm == true) {
                            await deleteAccount(context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.redAccent.withOpacity(0.4),
                  ),
                  child: Text(
                    'Yes, delete my account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
