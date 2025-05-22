import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../utils/colors.dart';

Widget buildOrderSummary(Map<String, dynamic> orderData, String orderType,
    DateTime orderDateTime, DateTime estimatedTime) {
  final deliveryDetails = orderData['deliveryDetails'] ?? {};
  final isScheduled = orderType == 'Schedule Order';
  final scheduledDate = deliveryDetails['scheduledDate'];
  final scheduledTimeSlot = deliveryDetails['scheduledTimeSlot'];

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: AppColors.backgroundColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order ID: ${orderData['orderId'] ?? 'N/A'}",
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Order Type: $orderType",
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          const SizedBox(height: 10),
          if (isScheduled) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text("Scheduled: $scheduledDate, $scheduledTimeSlot"),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                    "Est. Delivery: ${DateFormat('h:mm a').format(estimatedTime)}"),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

Widget buildItemList(List<Map<String, dynamic>> items) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: items.map((item) {
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'] ?? '',
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 50,
                width: 50,
                color: Colors.grey[100],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 50,
                width: 50,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          title: Text(item['productName'],
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text("${item['variantWeight']} × ${item['quantity']}"),
          trailing: Text(
            "₹${(item['price'] * item['quantity']).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    ),
  );
}

Widget buildPaymentSection(
    Map<String, dynamic> orderData, String paymentStatus) {
  final method = orderData['paymentMethod'] ?? 'Unknown';
  final isSuccess = paymentStatus.toLowerCase() == 'success';

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        const Icon(Icons.payment, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(child: Text("Paid via $method")),
        buildTag(
            paymentStatus.toUpperCase(), isSuccess ? Colors.green : Colors.red),
      ],
    ),
  );
}

Widget buildBillDetails(Map<String, dynamic> orderData) {
  final tip = orderData['deliveryTip'] ?? 0;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        buildBillRow(
            "Subtotal", "₹${orderData['subtotal'] ?? orderData['orderTotal']}"),
        buildBillRow("Delivery Charge", "₹${orderData['deliveryCharge'] ?? 0}"),
        if (tip > 0) buildBillRow("Tip", "₹$tip"),
        const Divider(),
        buildBillRow("Total", "₹${orderData['orderTotal']}", isBold: true),
      ],
    ),
  );
}

Widget buildAddressSection(Map<String, dynamic> orderData) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Card(
      color: const Color(0xFFF6F6F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: const Text("Delivery Address",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(orderData['shippingAddress'] ?? "Not Available"),
        leading: const Icon(Icons.location_on, color: Colors.redAccent),
      ),
    ),
  );
}

Widget buildTag(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

Widget buildBillRow(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        Text(value,
            style:
                isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
      ],
    ),
  );
}

Widget buildDivider() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(thickness: 1),
    );

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
