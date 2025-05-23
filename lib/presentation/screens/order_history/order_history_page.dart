import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';
import 'order_details/order_details_page.dart';
import 'order_history_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderHistoryPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(userId)
            .collection('orders')
            .orderBy('orderDateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders."));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return const Center(child: Text("No past orders."));
          }

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: OrderHistoryFunctions.fetchAllShopDetails(orders),
            builder: (context, shopSnapshot) {
              if (!shopSnapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondaryColor)));
              }

              final shopDetails = shopSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final data = order.data() as Map<String, dynamic>;
                  final items = data['items'] ?? [];
                  final firstItem = items.isNotEmpty ? items[0] : null;
                  final shopId = firstItem?['shopId'];

                  final shop = shopDetails[shopId] ??
                      {'shop_name': 'Unknown Shop', 'city': 'Unknown City'};

                  final orderTotal = data['orderTotal']?.toDouble() ?? 0;
                  final status = data['orderStatus'] ?? '';
                  final statusColor = status.toLowerCase() == 'delivered'
                      ? Colors.green
                      : Colors.orange;
                  final itemName = firstItem?['productName'] ?? '';
                  final itemQty = firstItem?['quantity'] ?? 1;
                  final itemImage = shop['shop_logo'];

                  final moreCount = items.length > 1 ? items.length - 1 : 0;
                  final dateTime = DateTime.parse(data['orderDateTime']);
                  final formattedDate =
                      DateFormat('MMMM d, h:mm a').format(dateTime);

                  final itemSummary = moreCount > 0
                      ? "$itemName ($itemQty) + $moreCount more"
                      : "$itemName ($itemQty)";

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.backgroundColor, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: itemImage ?? '',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey[100],
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Order Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Shop name + City
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        shop['shop_name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            status.toLowerCase() == 'delivered'
                                                ? Icons.check_circle
                                                : Icons.timelapse,
                                            color: statusColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Item Summary
// Text(
//   itemSummary,
//   style: const TextStyle(fontSize: 14),
// ),

                                const SizedBox(height: 4),

                                /// Order Date + City
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.location_on,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      shop['city'],
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                /// Price and details button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₹${orderTotal.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => OrderDetailsPage(
                                                orderData: data,
                                                shopId: shopId),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.receipt_long,
                                          size: 18,
                                          color: AppColors.secondaryColor),
                                      label: const Text("Details",
                                          style: TextStyle(
                                              color: AppColors.secondaryColor)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
