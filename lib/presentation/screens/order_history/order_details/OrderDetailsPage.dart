import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(orderData['items']);
    final status = orderData['orderStatus'] ?? 'Pending';
    final statusColor = _getStatusColor(status);
    final orderType = orderData['deliveryDetails']?['orderType'] ?? 'Delivery';
    final paymentStatus = orderData['paymentStatus'] ?? 'Pending';
    final orderDateTime = DateTime.parse(orderData['orderDateTime']);
    final estimatedTime = orderDateTime.add(const Duration(minutes: 30));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOrderSummary(
                status, statusColor, orderType, orderDateTime, estimatedTime),
            const SizedBox(height: 8),
            _buildItemList(items),
            _buildDivider(),
            _buildPaymentSection(orderData, paymentStatus),
            _buildDivider(),
            _buildBillDetails(orderData),
            _buildDivider(),
            _buildAddressSection(orderData),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(String status, Color statusColor, String orderType,
      DateTime orderDateTime, DateTime estimatedTime) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order ID: ${orderData['orderId'] ?? 'N/A'}",
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTag(status.toUpperCase(), statusColor),
                const SizedBox(width: 8),
                _buildTag(orderType, Colors.deepPurpleAccent),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                    "Est. Delivery: ${DateFormat('h:mm a').format(estimatedTime)}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item['imageUrl'],
                  height: 50, width: 50, fit: BoxFit.cover),
            ),
            title: Text(item['productName'],
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("${item['variantWeight']} × ${item['quantity']}"),
            trailing: Text(
                "₹${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentSection(
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
          _buildTag(paymentStatus.toUpperCase(),
              isSuccess ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _buildBillDetails(Map<String, dynamic> orderData) {
    final tip = orderData['deliveryTip'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildBillRow("Subtotal",
              "₹${orderData['subtotal'] ?? orderData['orderTotal']}"),
          _buildBillRow(
              "Delivery Charge", "₹${orderData['deliveryCharge'] ?? 0}"),
          if (tip > 0) _buildBillRow("Tip", "₹$tip"),
          const Divider(),
          _buildBillRow("Total", "₹${orderData['orderTotal']}", isBold: true),
        ],
      ),
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> orderData) {
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false}) {
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

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(thickness: 1),
      );

  Color _getStatusColor(String status) {
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
}
