import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import 'billing_details_dialog.dart';
import 'order_details_functions.dart';
import 'order_status_progress.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String shopId;

  const OrderDetailsPage({
    super.key,
    required this.orderData,
    required this.shopId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  int estimatedMinutes = 30;

  @override
  void initState() {
    super.initState();
    fetchEstimatedTime();
  }

  Future<void> fetchEstimatedTime() async {
    try {
      final docShops = await FirebaseFirestore.instance
          .collection('shops_settings')
          .doc(widget.shopId)
          .get();

      if (docShops.exists && docShops.data()?['estimatedTime'] != null) {
        setState(() {
          estimatedMinutes = docShops.data()!['estimatedTime'];
        });
        return;
      }

      final docOwnShops = await FirebaseFirestore.instance
          .collection('own_shops_settings')
          .doc(widget.shopId)
          .get();

      if (docOwnShops.exists && docOwnShops.data()?['estimatedTime'] != null) {
        setState(() {
          estimatedMinutes = docOwnShops.data()!['estimatedTime'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching estimated time: $e");
      // Keep fallback value of 30
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderData;
    final items = List<Map<String, dynamic>>.from(orderData['items']);
    final status = orderData['orderStatus'] ?? 'Pending';
    final statusColor = getStatusColor(status);
    final orderType = orderData['deliveryDetails']?['orderType'] ?? 'Delivery';
    final paymentStatus = orderData['paymentStatus'] ?? 'Pending';
    final orderDateTime = DateTime.parse(orderData['orderDateTime']);
    final estimatedTime =
        orderDateTime.add(Duration(minutes: estimatedMinutes));

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
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        buildPaymentStatusTag(paymentStatus),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Bill Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        Row(
                          children: [
                            Text(
                              "₹${orderData['orderTotal'] ?? 0}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.expand_more),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => BillingDetailsDialog(
                                      orderData: orderData),
                                );
                              },
                            ),
                          ],
                        ),
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
}
