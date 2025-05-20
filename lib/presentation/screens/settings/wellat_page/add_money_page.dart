import 'package:eqcart/presentation/screens/settings/wellat_page/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class AddMoneyPage extends StatefulWidget {
  @override
  _AddMoneyPageState createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  late Razorpay _razorpay;
  final amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _startPayment(double amount) {
    var options = {
      'key': 'rzp_live_7rk7sJYf7JnVOk',
      'amount': (amount * 100).toInt(), // in paise
      'name': 'EqCart Wallet',
      'description': 'Add Money to Wallet',
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    double amt = double.parse(amountController.text);
    await WalletService.updateBalance(amt);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("₹$amt added successfully!")));
    Navigator.pop(context);
  }

  Future<void> _handlePaymentError(PaymentFailureResponse response) async {
    double amt = double.parse(amountController.text);
    await WalletService.updateBalance(amt);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Payment failed")));
    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Money")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter Amount"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final enteredAmount = double.tryParse(amountController.text);
                if (enteredAmount != null && enteredAmount > 0) {
                  _startPayment(enteredAmount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Enter valid amount")));
                }
              },
              child: Text("Proceed to Pay"),
            ),
          ],
        ),
      ),
    );
  }
}
