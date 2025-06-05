import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';

Future<String?> showOTPDialog(
  BuildContext context,
  String phoneNumber,
  void Function() onResend,
) async {
  final TextEditingController otpController = TextEditingController();
  bool isExpired = false;
  Timer? timer;

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      timer = Timer(const Duration(minutes: 2), () {
        isExpired = true;
        (ctx as Element).markNeedsBuild();
      });

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "Enter OTP",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("OTP sent to $phoneNumber",
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: AppColors.primaryColor),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: "6-digit code",
                    hintStyle: TextStyle(color: Colors.grey),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.secondaryColor),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.secondaryColor),
                    ),
                  ),
                ),
                if (isExpired)
                  TextButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(context); // return null
                      onResend();
                    },
                    child: const Text("Resend OTP"),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(context); // cancel
                },
                child: const Text("Cancel",
                    style: TextStyle(color: AppColors.primaryColor)),
              ),
              ElevatedButton(
                onPressed: isExpired
                    ? null
                    : () {
                        final otp = otpController.text.trim();
                        if (otp.isNotEmpty) {
                          timer?.cancel();
                          Navigator.pop(context, otp);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text(
                  "Verify",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
