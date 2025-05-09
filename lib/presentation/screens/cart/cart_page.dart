import 'dart:async';

import 'package:eqcart/presentation/screens/cart/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';

import '../home/main_page.dart';
import 'add_tip_dialog.dart';
import 'checkout_bottom_sheet.dart';
import 'cart_item_widget.dart';
import 'order_type_selector.dart';
import 'bill_summary_widget.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool showCouponField = false;
  List<Map<String, dynamic>> cartItems = [];
  double totalAmount = 0;
  double deliveryTipAmount = 0;
  bool isOrderSummaryExpanded = false;
  final TextEditingController _couponController = TextEditingController();
  String orderType = 'Delivery Now';
  String selectedDate = 'Today';
  String selectedTime = '';
  List<String> dateSlots = [];
  List<String> timeSlots = [];
  late Timer _timer;
  bool isDeliveryNowEnabled = true;
  bool isTodayEnabled = true;

  String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    startTimerForOrderType();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Cart',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            )),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Cart Items
          ...cartItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return CartItemWidget(
              item: item,
              onQuantityChanged: (newQuantity) =>
                  updateQuantity(index, newQuantity),
              onDelete: () => _showDeleteConfirmationDialog(index),
            );
          }),

          Column(
            children: [
              const SizedBox(height: 5),
              _buildAddMoreProductsButton(),
              const SizedBox(height: 16),
              _buildCouponSection(),
            ],
          ),

          const SizedBox(height: 20),
          OrderTypeSelector(
            orderType: orderType,
            dateSlots: dateSlots,
            timeSlots: timeSlots,
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            isDeliveryNowEnabled: isDeliveryNowEnabled,
            isTodayEnabled: isTodayEnabled,
            onOrderTypeChanged: (type) {
              setState(() {
                orderType = type;
                if (orderType == 'Schedule Order') {
                  generateDateSlots();
                  listenToTimeSlots();
                }
              });
            },
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
            },
            onTimeSelected: (time) {
              setState(() {
                selectedTime = time;
              });
            },
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('addresses')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No addresses found.');
              }

              String? address;

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;

                // First check map_location
                if (data['map_location'] != null &&
                    data['map_location']['isDefault'] == true) {
                  address = data['map_location']['address'];
                  break;
                }
                // Then check manual_location (in case needed in future)
                else if (data['manual_location'] != null &&
                    data['manual_location']['isDefault'] == true) {
                  if (data['manual_location']['address'] != null) {
                    address = data['manual_location']['address'];
                    break;
                  }
                }
              }

              if (address == null) {
                return const Text('No default address set.');
              }
              return Card(
                color: Colors.white, // Set background color to white
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1), // Rounded corners
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ListTile(
                    leading: const Icon(Icons.location_on,
                        color: AppColors.secondaryColor),
                    title: Text(
                      address,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          BillSummaryWidget(
            isExpanded: isOrderSummaryExpanded,
            totalAmount: totalAmount,
            deliveryTipAmount: deliveryTipAmount,
            onToggleExpansion: () {
              setState(() {
                isOrderSummaryExpanded = !isOrderSummaryExpanded;
              });
            },
            onTipAdded: () {
              showDialog(
                context: context,
                builder: (context) =>
                    AddTipDialog(initialTip: deliveryTipAmount),
              ).then((selectedTip) {
                if (selectedTip != null) {
                  setState(() {
                    deliveryTipAmount = selectedTip;
                  });
                }
              });
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
      bottomNavigationBar: _buildCheckoutButton(),
    );
  }

  Widget _buildAddMoreProductsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add More',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.local_offer_outlined,
                  color: AppColors.secondaryColor),
            ),
            title: const Text("Apply Coupon",
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(showCouponField
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
              onPressed: () {
                setState(() {
                  showCouponField = !showCouponField;
                });
              },
            ),
          ),
          if (showCouponField)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: "Enter coupon code",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (orderType == 'Schedule Order') {
            final bool isTodaySelected = selectedDate == 'Today';
            final bool isTodayDisabled = DateTimeUtils.isDeliveryNowDisabled();
            final bool isInvalid = selectedDate.isEmpty ||
                selectedTime.isEmpty ||
                (isTodaySelected && isTodayDisabled);

            if (isInvalid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Please select a valid delivery date and time.')),
              );
              return; // don't proceed
            }
          } else if (orderType == 'Delivery Now') {
            if (DateTimeUtils.isDeliveryNowDisabled()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Delivery is not available right now. Please schedule your order.')),
              );
              return; // don't proceed
            }
          }
          final deliveryDetails = {
            'orderType': orderType,
            if (orderType == 'Schedule Order') ...{
              'scheduledDate': selectedDate,
              'scheduledTimeSlot': selectedTime,
            }
          };

          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => CheckoutBottomSheet(
              totalAmount: totalAmount + 25 + 10 + deliveryTipAmount,
              deliveryDetails: deliveryDetails,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Proceed to Checkout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text('₹${totalAmount + 25 + 10 + deliveryTipAmount}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void generateDateSlots() {
    dateSlots.clear();
    DateTime today = DateTime.now();
    for (int i = 0; i <= 9; i++) {
      DateTime date = today.add(Duration(days: i));
      String formattedDate;
      if (i == 0) {
        formattedDate = 'Today';
      } else {
        formattedDate = '${_weekdayName(date.weekday)} ${date.day}';
      }
      dateSlots.add(formattedDate);
    }
  }

  String _weekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  void listenToTimeSlots() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('cart')
        .doc(userId)
        .snapshots()
        .listen((cartSnapshot) async {
      if (!cartSnapshot.exists) return;

      final cartData = cartSnapshot.data();
      if (cartData == null || cartData.isEmpty) return;

      final firstEntry = cartData.values.first;

      if (firstEntry is List && firstEntry.isNotEmpty) {
        final firstProduct = firstEntry[0] as Map<String, dynamic>;
        final shopId = firstProduct['shopid'];

        if (shopId == null) return;

        FirebaseFirestore.instance
            .collection('own_shops_settings')
            .doc(shopId)
            .snapshots()
            .listen((ownShopSnapshot) async {
          if (ownShopSnapshot.exists) {
            final shopData = ownShopSnapshot.data() as Map<String, dynamic>?;

            if (shopData != null && shopData.containsKey('slotTiming')) {
              final slots = shopData['slotTiming'] as List<dynamic>? ?? [];
              setState(() {
                timeSlots = slots.map((e) => e.toString()).toList();
              });
            }
          } else {
            FirebaseFirestore.instance
                .collection('shops_settings')
                .doc(shopId)
                .snapshots()
                .listen((shopSnapshot) {
              if (shopSnapshot.exists) {
                final shopData = shopSnapshot.data() as Map<String, dynamic>?;

                if (shopData != null && shopData.containsKey('slotTiming')) {
                  final slots = shopData['slotTiming'] as List<dynamic>? ?? [];
                  setState(() {
                    timeSlots = slots.map((e) => e.toString()).toList();
                  });
                }
              }
            });
          }
        });
      }
    });
  }

  Future<void> fetchCartItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final cartSnapshot =
          await FirebaseFirestore.instance.collection('cart').doc(uid).get();

      if (cartSnapshot.exists) {
        List<Map<String, dynamic>> loadedItems = [];
        double total = 0;

        final cartData = cartSnapshot.data() as Map<String, dynamic>;

        cartData.forEach((skuKey, productList) {
          if (productList is List) {
            for (var product in productList) {
              if (product is Map<String, dynamic>) {
                final item = Map<String, dynamic>.from(product);
                item['sku_key'] = skuKey;
                item['variant_weight'] = product['variant_weight'] ?? '';
                loadedItems.add(item);
                total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
              }
            }
          }
        });

        setState(() {
          cartItems = loadedItems;
          totalAmount = total;
        });
      }
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (newQuantity < 1) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final productId = cartItems[index]['sku_id'];
    final variantWeight = cartItems[index]['variant_weight'];
    final skuKey = cartItems[index]['sku_key'];

    try {
      final cartRef = FirebaseFirestore.instance.collection('cart').doc(uid);
      final cartSnapshot = await cartRef.get();

      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>;
        final updatedCartData = Map<String, dynamic>.from(cartData);

        if (updatedCartData.containsKey(skuKey)) {
          List<dynamic> products = updatedCartData[skuKey];
          List<dynamic> updatedProducts = [];

          for (var product in products) {
            if (product is Map &&
                product['sku_id'] == productId &&
                product['variant_weight'] == variantWeight) {
              final updatedProduct = Map<String, dynamic>.from(product);
              updatedProduct['quantity'] = newQuantity;
              updatedProducts.add(updatedProduct);
            } else {
              updatedProducts.add(product);
            }
          }

          updatedCartData[skuKey] = updatedProducts;
          await cartRef.set(updatedCartData);

          setState(() {
            cartItems[index]['quantity'] = newQuantity;
            totalAmount = cartItems.fold(
              0,
              (sum, item) =>
                  sum + (item['price'] ?? 0) * (item['quantity'] ?? 1),
            );
          });
        }
      }
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update quantity')),
      );
    }
  }

  void startTimerForOrderType() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final currentHour = now.hour;

      // Disable Delivery Now and Today between 9 PM and 6 AM
      if (currentHour >= 21 || currentHour < 6) {
        if (isDeliveryNowEnabled || isTodayEnabled) {
          setState(() {
            isDeliveryNowEnabled = false;
            isTodayEnabled = false;
          });
        }
      } else {
        if (!isDeliveryNowEnabled || !isTodayEnabled) {
          setState(() {
            isDeliveryNowEnabled = true;
            isTodayEnabled = true;
          });
        }
      }
    });
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text(
            'Are you sure you want to remove this item from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteCartItem(index);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCartItem(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final skuKey = cartItems[index]['sku_key'];
    final productId = cartItems[index]['sku_id'];
    final variantWeight = cartItems[index]['variant_weight'];

    try {
      final cartRef = FirebaseFirestore.instance.collection('cart').doc(uid);
      final cartSnapshot = await cartRef.get();

      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>;
        final updatedCartData = Map<String, dynamic>.from(cartData);

        if (updatedCartData.containsKey(skuKey)) {
          List<dynamic> productList = updatedCartData[skuKey];

          productList.removeWhere((product) =>
              product['sku_id'] == productId &&
              product['variant_weight'] == variantWeight);

          if (productList.isEmpty) {
            updatedCartData.remove(skuKey);
          } else {
            updatedCartData[skuKey] = productList;
          }

          await cartRef.set(updatedCartData);

          setState(() {
            cartItems.removeAt(index);
            totalAmount = cartItems.fold(
              0,
              (sum, item) =>
                  sum + (item['price'] ?? 0) * (item['quantity'] ?? 1),
            );
          });
        }
      }
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
