import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../utils/colors.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(orderData['items']);
    final status = orderData['orderStatus'] ?? 'Pending';
    final statusColor = getStatusColor(status);
    final orderType = orderData['deliveryDetails']?['orderType'] ?? 'Delivery';
    final paymentStatus = orderData['paymentStatus'] ?? 'Pending';
    final orderDateTime = DateTime.parse(orderData['orderDateTime']);
    final estimatedTime = orderDateTime.add(const Duration(minutes: 30));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Order Details",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Status Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order Status",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        buildStatusTag(status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: getStatusProgress(status),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildProgressStep("Placed", status, 0),
                        buildProgressStep("Packing", status, 1),
                        buildProgressStep("On the way", status, 2),
                        buildProgressStep("Delivered", status, 3),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Order Summary Card
            buildOrderSummary(
                orderData, orderType, orderDateTime, estimatedTime),

            // Items List
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            color: AppColors.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          "Order Items (${items.length})",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  ...items.map((item) => buildOrderItem(item)).toList(),
                ],
              ),
            ),

            // Payment & Bill Details
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Payment Status
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.payment, color: AppColors.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Payment",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${orderData['paymentMethod'] ?? 'Unknown'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                              ]),
                        ),
                        buildPaymentStatusTag(paymentStatus),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Bill Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt, color: AppColors.primaryColor),
                            SizedBox(width: 12),
                            Text(
                              "Bill Details",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        buildBillRow("Subtotal",
                            "₹${orderData['subtotal'] ?? orderData['orderTotal']}"),
                        buildBillRow("Delivery Charge",
                            "₹${orderData['deliveryCharge'] ?? 0}"),
                        if ((orderData['deliveryTip'] ?? 0) > 0)
                          buildBillRow("Tip", "₹${orderData['deliveryTip']}"),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 8),
                        buildBillRow("Total", "₹${orderData['orderTotal']}",
                            isBold: true, isTotal: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Delivery Address
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: AppColors.primaryColor),
                        const SizedBox(width: 12),
                        const Text(
                          "Delivery Address",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      orderData['shippingAddress'] ?? "Not Available",
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusTag(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget buildPaymentStatusTag(String status) {
    final isSuccess = status.toLowerCase() == 'success';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: isSuccess ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget buildProgressStep(String title, String currentStatus, int step) {
    final isCompleted = getStatusIndex(currentStatus) >= step;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.secondaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isCompleted ? AppColors.secondaryColor : Colors.grey,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget buildOrderSummary(Map<String, dynamic> orderData, String orderType,
      DateTime orderDateTime, DateTime estimatedTime) {
    final deliveryDetails = orderData['deliveryDetails'] ?? {};
    final isScheduled = orderType == 'Schedule Order';
    final scheduledDate = deliveryDetails['scheduledDate'];
    final scheduledTimeSlot = deliveryDetails['scheduledTimeSlot'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long,
                      color: AppColors.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Summary",
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800]),
                    ),
                    Text(
                      "ID: ${orderData['orderId'] ?? 'N/A'}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Type",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orderType,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ]),
                ),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Date",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(orderDateTime),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isScheduled ? "Scheduled Date" : "Order Time",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isScheduled
                              ? "$scheduledDate, $scheduledTimeSlot"
                              : DateFormat('h:mm a').format(orderDateTime),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ]),
                ),
                if (!isScheduled)
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Est. Delivery",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('h:mm a').format(estimatedTime),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'] ?? '',
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 60,
                width: 60,
                color: Colors.grey[100],
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryColor)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 60,
                width: 60,
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text("${item['variantWeight']} × ${item['quantity']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Text(
            "₹${(item['price'] * item['quantity']).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget buildBillRow(String label, String value,
      {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? AppColors.primaryColor : Colors.grey[700],
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 15 : 14)),
          Text(value,
              style: TextStyle(
                  color: isTotal ? AppColors.primaryColor : Colors.grey[700],
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 15 : 14)),
        ],
      ),
    );
  }
}

// Helper functions
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'pending':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

int getStatusIndex(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 0;
    case 'preparing':
      return 1;
    case 'on the way':
      return 2;
    case 'delivered':
      return 3;
    case 'cancelled':
      return -1;
    default:
      return 0;
  }
}

double getStatusProgress(String status) {
  final index = getStatusIndex(status);
  if (index == -1) return 0; // Cancelled
  return (index + 1) / 4;
}
