import 'package:flutter/material.dart';

import '../../../../utils/colors.dart';

class BillingDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const BillingDetailsDialog({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final amountDetails = orderData['amountDetails'] ?? {};
    final List<Map<String, dynamic>> summaryFields = [
      {'label': 'Subtotal', 'key': 'subtotal'},
      {'label': 'Item Discount', 'key': 'itemDiscount', 'isDiscount': true},
      {'label': 'Delivery Fee', 'key': 'deliveryFee'},
      {'label': 'Taxes & Charges', 'key': 'taxesCharges'},
      {'label': 'Gift Packing Charge', 'key': 'giftPacking'},
      {'label': 'Delivery Tip', 'key': 'deliveryTip'},
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.backgroundColor,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Bill Summary",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),

            ...summaryFields.map((field) {
              final value = amountDetails[field['key']];
              if (value == null) return const SizedBox();

              final isDiscount = field['isDiscount'] == true;
              final displayValue = isDiscount ? '-₹$value' : '₹$value';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      field['label']!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDiscount ? Colors.red : Colors.black87,
                        fontWeight:
                            isDiscount ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(thickness: 1.2, height: 30),

            // Total Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                  Text(
                    "₹${amountDetails['total'] ?? orderData['orderTotal']}",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
