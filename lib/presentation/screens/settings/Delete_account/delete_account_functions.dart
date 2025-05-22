import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> deleteAccount(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;
  final firestore = FirebaseFirestore.instance;

  try {
    final ordersSnapshot = await firestore
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Account cannot be deleted until all orders are marked as Delivered.'),
        ),
      );
      return;
    }

    final userDoc = await firestore.collection('users').doc(uid).get();
    final cartDoc = await firestore.collection('cart').doc(uid).get();

    await firestore.collection('deleted_users').doc(uid).set({
      'userData': userDoc.exists ? userDoc.data() : null,
      'cartData': cartDoc.exists ? cartDoc.data() : null,
      'deletedAt': FieldValue.serverTimestamp(),
    });

    await firestore.collection('users').doc(uid).delete();
    await firestore.collection('cart').doc(uid).delete();

    await FirebaseAuth.instance.signOut();

    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  } catch (e) {
    print('Error deleting account: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Something went wrong. Please try again.')),
    );
  }
}
