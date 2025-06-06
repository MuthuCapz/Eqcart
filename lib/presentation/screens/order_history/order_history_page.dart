import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';
import 'cancel_order_dialog.dart';
import 'order_details/order_details_page.dart';
import 'order_history_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
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
                  final cancelledTime = (shop['cancelledTime'] ?? 0) * 60;
                  final now = DateTime.now();
                  final orderPlacedTime = DateTime.parse(data['orderDateTime']);
                  final secondsSinceOrder =
                      now.difference(orderPlacedTime).inSeconds;
                  final isCancellable = secondsSinceOrder <= cancelledTime;
                  bool isBlurred = status.toLowerCase() == 'delivered' ||
                      status.toLowerCase() == 'cancelled';
                  bool cancellable = isCancellable && !isBlurred;

                  return Stack(
                    children: [
                      IgnorePointer(
                        ignoring: isBlurred,
                        child: Opacity(
                          opacity: isBlurred ? 0.5 : 1.0,
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.backgroundColor,
                                    Colors.white
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  //  Product Image block
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
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        height: 80,
                                        width: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  //  Order Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Shop name and status badge
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    status.toLowerCase() ==
                                                            'delivered'
                                                        ? Icons.check_circle
                                                        : Icons
                                                            .timelapse_outlined,
                                                    color: statusColor,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.location_on,
                                                size: 14,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              shop['city'],
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        /// Price + Buttons
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
                                            Row(
                                              children: [
                                                if (!isBlurred)
                                                  TextButton.icon(
                                                    onPressed: isCancellable
                                                        ? () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) =>
                                                                  CancelOrderDialog(
                                                                userId: userId,
                                                                orderId:
                                                                    order.id,
                                                              ),
                                                            );
                                                          }
                                                        : () {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    "Your order is already picked, so you cannot cancel."),
                                                              ),
                                                            );
                                                          },
                                                    icon: Icon(Icons.cancel,
                                                        size: 18,
                                                        color: isCancellable
                                                            ? Colors.red
                                                            : Colors.red
                                                                .withOpacity(
                                                                    0.4)),
                                                    label: Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: isCancellable
                                                            ? Colors.red
                                                            : Colors.red
                                                                .withOpacity(
                                                                    0.4),
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 1),

                                                //  Always clickable
                                                TextButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            OrderDetailsPage(
                                                                orderData: data,
                                                                shopId: shopId),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                      Icons.receipt_long,
                                                      size: 18,
                                                      color: AppColors
                                                          .secondaryColor),
                                                  label: const Text("Details",
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .secondaryColor)),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),

                                        if (cancellable)
                                          CancelableOrderTimer(
                                            orderPlacedTime: orderPlacedTime,
                                            cancelWindowInSeconds:
                                                cancelledTime,
                                            onExpire: () {
                                              setState(() {
                                                cancellable = false;
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isBlurred)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                    ],
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

class CancelableOrderTimer extends StatefulWidget {
  final DateTime orderPlacedTime;
  final int cancelWindowInSeconds;
  final VoidCallback onExpire;

  const CancelableOrderTimer({
    super.key,
    required this.orderPlacedTime,
    required this.cancelWindowInSeconds,
    required this.onExpire,
  });

  @override
  State<CancelableOrderTimer> createState() => _CancelableOrderTimerState();
}

class _CancelableOrderTimerState extends State<CancelableOrderTimer> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final cancelDeadline = widget.orderPlacedTime
        .add(Duration(seconds: widget.cancelWindowInSeconds));
    final difference = cancelDeadline.difference(now);

    if (difference.isNegative && _timeLeft != Duration.zero) {
      widget.onExpire(); // Notify parent to disable Cancel button
    }

    setState(() {
      _timeLeft = difference.isNegative ? Duration.zero : difference;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return const Text(
        "Cancellation expired",
        style: TextStyle(color: Colors.red, fontSize: 12),
      );
    }

    final minutes =
        _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text(
      "Cancel in $minutes:$seconds",
      style: const TextStyle(fontSize: 12, color: AppColors.primaryColor),
    );
  }
}
