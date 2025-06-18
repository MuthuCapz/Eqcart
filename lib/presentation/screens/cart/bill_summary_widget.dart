import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class BillSummaryWidget extends StatelessWidget {
  final bool isExpanded;
  final double totalAmount;
  final double deliveryTipAmount;
  final VoidCallback onToggleExpansion;
  final VoidCallback onTipAdded;
  final Map<String, dynamic>? appliedCoupon; // Add this parameter

  const BillSummaryWidget({
    super.key,
    required this.isExpanded,
    required this.totalAmount,
    required this.deliveryTipAmount,
    required this.onToggleExpansion,
    required this.onTipAdded,
    this.appliedCoupon, // Add this to constructor
  });

  // Helper method to calculate discount amount
  static double calculateDiscount({
    required double subtotal,
    required Map<String, dynamic>? coupon,
  }) {
    if (coupon == null) return 0.0;

    // Check minimum order value if exists
    final minOrderValue = coupon['minimumOrderValue']?.toDouble() ?? 0.0;
    if (subtotal < minOrderValue) return 0.0;

    final discountType = coupon['discountType'] ?? 'percentage';
    final discountValue = coupon['discount']?.toDouble() ?? 0.0;

    if (discountType == 'fixed') {
      return discountValue;
    } else {
      return (subtotal * discountValue) / 100;
    }
  }

  // Static method for calculating total
  static double calculateTotal({
    required double totalAmount,
    required double deliveryTipAmount,
    required Map<String, dynamic>? appliedCoupon,
  }) {
    final double discountAmount = calculateDiscount(
      subtotal: totalAmount,
      coupon: appliedCoupon,
    );
    final double subtotalAfterDiscount = totalAmount - discountAmount;
    return subtotalAfterDiscount + 25 + 10 + 30 + deliveryTipAmount;
  }

  // Instance version that uses the static methods
  double get calculatedTotal {
    return calculateTotal(
      totalAmount: totalAmount,
      deliveryTipAmount: deliveryTipAmount,
      appliedCoupon: appliedCoupon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double discountAmount = calculateDiscount(
      subtotal: totalAmount,
      coupon: appliedCoupon,
    );
    final double total = calculatedTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggleExpansion,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      '₹${total.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBillRow('Subtotal', totalAmount),
                if (appliedCoupon != null)
                  _buildDiscountRow(
                    'Item Discount',
                    discountAmount,
                    isDiscount: true,
                  ),
                _buildBillRow('Delivery Fee', 25),
                _buildBillRow('Taxes & Charges', 10),
                _buildBillRow('Gift Packing Charge', 30),
                _buildBillRow(
                  'Delivery Tips',
                  deliveryTipAmount,
                  onTapTip: onTipAdded,
                ),
                const Divider(height: 24),
                _buildBillRow(
                  'Total',
                  total,
                  isTotal: true,
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    double amount, {
    bool isTotal = false,
    VoidCallback? onTapTip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          GestureDetector(
            onTap: onTapTip,
            child: Text(
              amount == 0 && label == 'Delivery Tips'
                  ? 'Add Tip'
                  : '₹${amount.toInt()}',
              style: TextStyle(
                color: amount == 0 && label == 'Delivery Tips'
                    ? Colors.red
                    : Colors.black,
                fontWeight: amount == 0 && label == 'Delivery Tips'
                    ? FontWeight.bold
                    : isTotal
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            '-₹${amount.toInt()}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
