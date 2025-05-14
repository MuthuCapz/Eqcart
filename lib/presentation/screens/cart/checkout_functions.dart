import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'order_service.dart';

class PaymentService {
  late Razorpay _razorpay;
  final BuildContext context;
  final double orderTotalAmount;
  final Map<String, dynamic> deliveryDetails;
  final Function onOrderCompleted;
  final String? selectedAddress;

  double _walletBalance = 0.0;
  bool _walletDeducted = false;

  PaymentService({
    required this.context,
    required this.orderTotalAmount,
    required this.deliveryDetails,
    required this.onOrderCompleted,
    required this.selectedAddress,
  });

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<void> handlePlaceOrder() async {
    _walletBalance = await getWalletBalance();
    if (_walletBalance >= orderTotalAmount) {
      await deductFromWallet(orderTotalAmount);
      _walletDeducted = true;
      onOrderCompleted();
      showMessage('Order placed using wallet!');
    } else {
      if (_walletBalance > 0) {
        await deductFromWallet(_walletBalance);
        _walletDeducted = true;
      }
      double remainingAmount = orderTotalAmount - _walletBalance;
      openCheckout(remainingAmount);
    }
  }

  void openCheckout(double payableAmount) {
    var options = {
      'key': 'rzp_live_7rk7sJYf7JnVOk',
      'amount': (payableAmount * 100).toInt(),
      'name': 'EqCart',
      'description': 'Order Payment',
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    showMessage('Payment Successful: ${response.paymentId}');
    onOrderCompleted();
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    showMessage('Payment Failed: ${response.message}');

    await OrderService.createOrder(
      orderTotal: orderTotalAmount,
      paymentStatus: 'failure',
      paymentMethod: 'Razorpay',
      deliveryDetails: deliveryDetails,
      shippingAddress: selectedAddress ?? 'N/A',
      couponCode: 'SUMMER10',
      deliveryTip: 10,
    );

    onOrderCompleted();
    if (_walletDeducted) {
      // Payment failed, refund back to wallet
      await refundWallet(_walletBalance);
      _walletDeducted = false;
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    showMessage('External Wallet: ${response.walletName}');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Firebase Wallet Functions

  static Future<double> getWalletBalance() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('walletData')
        .get();

    if (snapshot.exists) {
      return (snapshot.data() as Map<String, dynamic>)['balance']?.toDouble() ??
          0.0;
    }
    return 0.0;
  }

  static Future<void> deductFromWallet(double amount) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('walletData');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Wallet does not exist!");
      }
      double currentBalance =
          (snapshot.data() as Map<String, dynamic>)['balance']?.toDouble() ??
              0.0;
      double newBalance = currentBalance - amount;
      if (newBalance < 0) newBalance = 0;
      transaction.update(docRef, {'balance': newBalance});
    });
  }

  static Future<void> refundWallet(double amount) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('walletData');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Wallet does not exist!");
      }
      double currentBalance =
          (snapshot.data() as Map<String, dynamic>)['balance']?.toDouble() ??
              0.0;
      double newBalance = currentBalance + amount;
      transaction.update(docRef, {'balance': newBalance});
    });
  }

  static Stream<double> walletBalanceStream() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('walletData')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return (snapshot.data()?['balance'] ?? 0).toDouble();
      }
      return 0.0;
    });
  }
}
