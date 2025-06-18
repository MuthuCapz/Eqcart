import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../home/main_page.dart';
import 'checkout_functions.dart';

class CheckoutBottomSheet extends StatefulWidget {
  final double totalAmount;
  final Map<String, dynamic> deliveryDetails;
  final String? selectedAddress;
  final double deliveryTipAmount;
  final Map<String, dynamic>? appliedCoupon;
  final VoidCallback onPaymentFailure;
  final double subtotal;
  final double itemDiscount;
  final double deliveryFee;
  final double taxesCharges;
  final double giftPackingCharge;

  const CheckoutBottomSheet({
    Key? key,
    required this.totalAmount,
    required this.deliveryDetails,
    required this.selectedAddress,
    required this.deliveryTipAmount,
    this.appliedCoupon,
    required this.onPaymentFailure,
    required this.subtotal,
    required this.itemDiscount,
    required this.deliveryFee,
    required this.taxesCharges,
    required this.giftPackingCharge,
  }) : super(key: key);

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  bool isWalletUsed = false;
  late PaymentService paymentService;
  double walletBalance = 0.0;

  String getCouponDiscountText(Map<String, dynamic> coupon) {
    final discountType = coupon['discountType'];
    final discountValue = coupon['discount'];

    if (discountType == 'fixed') {
      return '₹${discountValue.toString()} OFF';
    } else if (discountType == 'percentage') {
      return '${discountValue.toString()}% OFF';
    }
    return 'Discount Applied';
  }

  @override
  void initState() {
    super.initState();

    String? couponDiscountText;
    if (widget.appliedCoupon != null) {
      couponDiscountText = getCouponDiscountText(widget.appliedCoupon!);
    }

    paymentService = PaymentService(
      context: context,
      orderTotalAmount: widget.totalAmount,
      deliveryDetails: widget.deliveryDetails,
      deliveryTipAmount: widget.deliveryTipAmount,
      appliedCoupon: widget.appliedCoupon,
      couponDiscountText: couponDiscountText,
      subtotal: widget.subtotal,
      itemDiscount: widget.itemDiscount,
      deliveryFee: widget.deliveryFee,
      taxesCharges: widget.taxesCharges,
      giftPackingCharge: widget.giftPackingCharge,
      onPaymentFailure: widget.onPaymentFailure,
      onOrderCompleted: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderSuccessPage()),
        );
      },
      selectedAddress: widget.selectedAddress,
    );
    paymentService.init();
    fetchWalletBalance();
  }

  @override
  void dispose() {
    paymentService.dispose();
    super.dispose();
  }

  Future<void> fetchWalletBalance() async {
    walletBalance = await PaymentService.getWalletBalance();
    setState(() {});
  }

  void onPlaceOrderPressed() {
    if (isWalletUsed) {
      paymentService.handlePlaceOrder();
    } else {
      paymentService.openCheckout(widget.totalAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 50,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Payment Methods
          Column(
            children: [
              _buildPaymentOption(
                icon: Image.asset('assets/images/google_logo.png', height: 28),
                title: "Pay with Google Pay",
                onTap: () => paymentService.openCheckout(widget.totalAmount),
              ),
              const SizedBox(height: 16),
              _buildWalletOption(),
            ],
          ),

          const SizedBox(height: 24),

          // Show coupon summary if available
          if (widget.appliedCoupon != null) ...[
            _buildCouponSummary(widget.appliedCoupon!),
            const SizedBox(height: 16),
          ],

          // Total + Place Order
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: onPlaceOrderPressed,
                child: const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.secondaryColor, width: 0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.secondaryColor, width: 0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet,
              color: AppColors.primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Eqcart Wallet",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Balance: ₹${walletBalance.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            activeColor: AppColors.primaryColor,
            value: isWalletUsed,
            onChanged: (value) {
              setState(() {
                isWalletUsed = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSummary(Map<String, dynamic> coupon) {
    final code = coupon['code'] ?? '';
    final discountText = getCouponDiscountText(coupon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Coupon Applied: $code ($discountText)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 140, color: AppColors.primaryColor),
            const SizedBox(height: 20),
            const Text(
              "Order Successful!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
              child: const Text(
                'Continue Shopping',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
