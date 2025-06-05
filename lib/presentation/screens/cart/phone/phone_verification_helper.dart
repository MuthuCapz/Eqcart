import 'package:eqcart/presentation/screens/cart/phone/phone_number_dialog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_verification_dialog.dart';

Future<bool> checkAndVerifyPhoneNumber(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;

  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final phone = userDoc.data()?['phone'];
  if (phone != null && phone.toString().trim().isNotEmpty) return true;

  final phoneNumber = await showPhoneNumberDialog(context);
  if (phoneNumber == null || phoneNumber.trim().isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Phone number required")));
    return false;
  }

  bool otpVerified = false;
  String verificationId = '';

  Future<void> sendOTP() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(minutes: 2),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.currentUser
              ?.updatePhoneNumber(credential);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'phone': phoneNumber});
          otpVerified = true;
        } catch (_) {}
      },
      verificationFailed: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification failed: ${e.message}")));
      },
      codeSent: (String verId, int? resendToken) async {
        verificationId = verId;
        final otp = await showOTPDialog(context, phoneNumber, sendOTP);
        if (otp != null) {
          try {
            final credential = PhoneAuthProvider.credential(
                verificationId: verificationId, smsCode: otp);
            await FirebaseAuth.instance.currentUser
                ?.updatePhoneNumber(credential);
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'phone': phoneNumber});
            otpVerified = true;
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid OTP. Try again.")),
            );
          }
        }
      },
      codeAutoRetrievalTimeout: (verId) => verificationId = verId,
    );
  }

  await sendOTP();

  return otpVerified;
}
