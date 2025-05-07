import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class BillSummaryWidget extends StatelessWidget {
  final bool isExpanded;
  final double totalAmount;
  final double deliveryTipAmount;
  final VoidCallback onToggleExpansion;
  final VoidCallback onTipAdded;

  const BillSummaryWidget({
    super.key,
    required this.isExpanded,
    required this.totalAmount,
    required this.deliveryTipAmount,
    required this.onToggleExpansion,
    required this.onTipAdded,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
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
                  totalAmount + 25 + 10 + deliveryTipAmount,
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
              amount == 0 ? 'Add Tip' : '₹${amount.toInt()}',
              style: TextStyle(
                color: amount == 0 ? Colors.red : Colors.black,
                fontWeight: amount == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
