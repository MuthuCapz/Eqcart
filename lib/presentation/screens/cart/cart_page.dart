import 'dart:async';

import 'package:eqcart/presentation/screens/cart/phone/phone_verification_helper.dart';
import 'package:eqcart/presentation/screens/cart/utils/date_time_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';

import '../home/main_page.dart';
import 'add_tip_dialog.dart';
import 'address_showing_widget.dart';
import 'checkout_bottom_sheet.dart';
import 'cart_item_widget.dart';
import 'empty_cart_widget.dart';
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
  String? selectedAddress;
  bool _isRefreshing = false;
  bool _isLoading = false;
  bool _isDataLoaded = false;
  String userId = FirebaseAuth.instance.currentUser!.uid;
  StreamSubscription<DocumentSnapshot>? _cartSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    startTimerForOrderType();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _isDataLoaded = false;
    });

    // Load cached data first for immediate display
    final cachedItems = await _getCachedCartItems();
    if (cachedItems != null && mounted) {
      setState(() {
        cartItems = cachedItems;
        totalAmount = _calculateTotal(cachedItems);
        _isDataLoaded = true;
      });
    }

    // Then fetch fresh data and listen for updates
    await fetchCartItems();
    listenToCartChanges();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>?> _getCachedCartItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));

      if (cartSnapshot.exists) {
        return _processCartData(cartSnapshot.data()!, checkAvailability: false);
      }
    } catch (e) {
      print('Error getting cached cart: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _processCartData(
    Map<String, dynamic> cartData, {
    bool checkAvailability = true,
  }) async {
    List<Map<String, dynamic>> loadedItems = [];

    for (var skuKey in cartData.keys) {
      final productList = cartData[skuKey];
      if (productList is List) {
        for (var product in productList) {
          if (product is Map<String, dynamic>) {
            final item = Map<String, dynamic>.from(product);
            item['sku_key'] = skuKey;
            item['category'] = product['category'] ?? '';
            item['variant_weight'] =
                product['variant_weight']?.toString() ?? '';
            item['shopid'] = product['shopid'] ?? '';

            if (checkAvailability) {
              item['is_available'] = await checkProductAvailability(
                    skuKey,
                    item['variant_weight'],
                    item['category'],
                  ) &&
                  await isShopStillActive(item['shopid']);
            } else {
              item['is_available'] = true; // Assume available for cached data
            }

            loadedItems.add(item);
          }
        }
      }
    }
    if (checkAvailability && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUnavailableItems();
      });
    }
    return loadedItems;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(0, (sum, item) {
      return sum +
          (item['is_available']
              ? (item['price'] ?? 0) * (item['quantity'] ?? 1)
              : 0);
    });
  }

  void listenToCartChanges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _cartSubscription = FirebaseFirestore.instance
        .collection('cart')
        .doc(uid)
        .snapshots()
        .listen((cartSnapshot) async {
      if (!cartSnapshot.exists) return;

      List<Map<String, dynamic>> loadedItems = [];
      double total = 0;

      final cartData = cartSnapshot.data() as Map<String, dynamic>;

      for (var skuKey in cartData.keys) {
        final productList = cartData[skuKey];
        if (productList is List) {
          for (var product in productList) {
            if (product is Map<String, dynamic>) {
              final item = Map<String, dynamic>.from(product);
              item['sku_key'] = skuKey;
              item['category'] = product['category'] ?? '';
              item['variant_weight'] =
                  product['variant_weight']?.toString() ?? '';
              item['shopid'] = product['shopid'] ?? '';

              final isAvailable = await checkProductAvailability(
                skuKey,
                item['variant_weight'],
                item['category'],
              );

              final isShopActive = await isShopStillActive(item['shopid']);

              item['is_available'] = isAvailable && isShopActive;
              loadedItems.add(item);

              if (item['is_available']) {
                total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
              }
            }
          }
        }
      }

      setState(() {
        cartItems = loadedItems;
        totalAmount = total;
      });
    });
  }

  void _checkForUnavailableItems() {
    final unavailableItems =
        cartItems.where((item) => !item['is_available']).toList();

    if (unavailableItems.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUnavailableItemsDialog(unavailableItems);
      });
    }
  }

  void _showUnavailableItemsDialog(
      List<Map<String, dynamic>> unavailableItems) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent tap outside to close
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button closing
        child: AlertDialog(
          title: const Text('Unavailable Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following items are no longer available:'),
              const SizedBox(height: 10),
              ...unavailableItems
                  .map(
                    (item) => Text(
                        '- ${item['product_name']} (${item['variant_weight']})'),
                  )
                  .toList(),
              const SizedBox(height: 10),
              const Text('Would you like to remove them from your cart?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeUnavailableItems(unavailableItems);
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeUnavailableItems(List<Map<String, dynamic>> items) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final cartRef = FirebaseFirestore.instance.collection('cart').doc(uid);
      final cartSnapshot = await cartRef.get();

      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>;
        final updatedCartData = Map<String, dynamic>.from(cartData);

        for (var item in items) {
          final skuKey = item['sku_key'];
          final productId = item['sku_id'];
          final variantWeight = item['variant_weight'];

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
          }
        }

        await cartRef.set(updatedCartData);

        // Update local state
        setState(() {
          cartItems.removeWhere((item) => !item['is_available']);
          totalAmount = _calculateTotal(cartItems);
        });
      }
    } catch (e) {
      print('Error removing unavailable items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove unavailable items')),
      );
    }
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
      body: Stack(
        children: [
          if (cartItems.isEmpty && _isDataLoaded)
            const EmptyCartWidget()
          else
            RefreshIndicator(
              onRefresh: () => fetchCartItems(isRefresh: true),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (_isLoading || _isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),

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
                  StreamBuilder<bool>(
                    stream: DateTimeUtils.isDeliveryNowDisabledStream(),
                    builder: (context, snapshot) {
                      final isDeliveryNowDisabled = snapshot.data ?? false;

                      return OrderTypeSelector(
                        orderType: orderType,
                        dateSlots: dateSlots,
                        timeSlots: timeSlots,
                        selectedDate: selectedDate,
                        selectedTime: selectedTime,
                        isDeliveryNowEnabled: !isDeliveryNowDisabled,
                        isTodayEnabled: !isDeliveryNowDisabled,
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
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  DefaultAddressWidget(
                    userId: userId,
                    onAddressSelected: (address) {
                      setState(() {
                        selectedAddress = address;
                      });
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
            ),
          if (_isLoading && !_isDataLoaded)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: cartItems.isNotEmpty ? _buildCheckoutButton() : null,
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
    final isButtonEnabled = _isDataLoaded && !_isRefreshing && !_isLoading;
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
        onPressed: isButtonEnabled
            ? () async {
                // Show loading if cart is empty or refreshing
                if (cartItems.isEmpty || _isRefreshing) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please wait while we update your cart')),
                  );
                  return;
                }

                // Check if all items are unavailable
                if (cartItems.every((item) => !item['is_available'])) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'All items in your cart are currently unavailable')),
                  );
                  return;
                }

                // Check address selection
                if (selectedAddress == null || selectedAddress!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a delivery address')),
                  );
                  return;
                }
                final phoneCheckPassed = await checkAndVerifyPhoneNumber(
                    context); // CALL NEW FUNCTION
                if (!phoneCheckPassed) return;
                // Check delivery time validity
                final bool isDisabledNow =
                    await DateTimeUtils.isDeliveryNowDisabledStream().first;

                if (orderType == 'Scheduled Order') {
                  final bool isTodaySelected = selectedDate == 'Today';
                  final bool isInvalid = selectedDate.isEmpty ||
                      selectedTime.isEmpty ||
                      (isTodaySelected && isDisabledNow);

                  if (isInvalid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please select a valid delivery date and time.'),
                      ),
                    );
                    return;
                  }
                } else if (orderType == 'Delivery Now' && isDisabledNow) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Delivery is not available right now. Please schedule your order.'),
                    ),
                  );
                  return;
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
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => CheckoutBottomSheet(
                    totalAmount: totalAmount + 25 + 10 + deliveryTipAmount,
                    deliveryDetails: deliveryDetails,
                    selectedAddress: selectedAddress,
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isButtonEnabled ? AppColors.secondaryColor : Colors.grey,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: isButtonEnabled ? 4 : 0,
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

  Future<void> fetchCartItems({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final cartSnapshot =
          await FirebaseFirestore.instance.collection('cart').doc(uid).get();

      if (cartSnapshot.exists) {
        List<Map<String, dynamic>> loadedItems = [];
        double total = 0;

        final cartData = cartSnapshot.data() as Map<String, dynamic>;

        for (var skuKey in cartData.keys) {
          final productList = cartData[skuKey];
          if (productList is List) {
            for (var product in productList) {
              if (product is Map<String, dynamic>) {
                final item = Map<String, dynamic>.from(product);
                item['sku_key'] = skuKey;
                item['category'] = product['category'] ?? '';
                item['variant_weight'] =
                    product['variant_weight']?.toString() ?? '';
                item['shopid'] = product['shopid'] ?? '';

                bool isAvailable = await checkProductAvailability(
                    skuKey, item['variant_weight'], item['category']);

                bool isShopActive = await isShopStillActive(item['shopid']);
                item['is_available'] = isAvailable && isShopActive;
                loadedItems.add(item);

                if (item['is_available']) {
                  total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
                }
              }
            }
          }
        }

        setState(() {
          cartItems = loadedItems;
          totalAmount = total;
          _isDataLoaded = true;
          if (isRefresh) _isRefreshing = false;
        });

        // Check for unavailable items after loading
        _checkForUnavailableItems();
      }
    } catch (e) {
      print('Error fetching cart items: $e');
      if (isRefresh) {
        setState(() => _isRefreshing = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to refresh cart')),
      );
    }
  }

  /// Helper function to check if a shop is still active
  Future<bool> isShopStillActive(String shopId) async {
    try {
      final shopRef =
          FirebaseFirestore.instance.collection('shops').doc(shopId);
      final ownShopRef =
          FirebaseFirestore.instance.collection('own_shops').doc(shopId);

      final shopDoc = await shopRef.get();
      if (shopDoc.exists && shopDoc.data()?['isActive'] == true) {
        return true;
      }

      final ownShopDoc = await ownShopRef.get();
      if (ownShopDoc.exists && ownShopDoc.data()?['isActive'] == true) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking shop activity for $shopId: $e');
      return false;
    }
  }

  Future<bool> checkProductAvailability(
      String skuId, String variantWeight, String category) async {
    try {
      print(
          'Checking stock for SKU: $skuId, Variant: $variantWeight, Category: $category');

      if (category.isEmpty) return false;

      // First check in shops_products
      final shopsQuery =
          await FirebaseFirestore.instance.collection('shops_products').get();

      for (final shopDoc in shopsQuery.docs) {
        final productDoc = await FirebaseFirestore.instance
            .collection('shops_products')
            .doc(shopDoc.id)
            .collection(category)
            .doc(skuId)
            .get();

        if (productDoc.exists) {
          final productData = productDoc.data()!;
          print('Found in shops_products: $productData');

          if (productData['variants'] != null && variantWeight.isNotEmpty) {
            final variants = productData['variants'] as List;
            for (var variant in variants) {
              final v = variant as Map<String, dynamic>;
              if (v['volume'] == variantWeight) {
                return v['stock'] == 'Instock' || v['stock'] == 'In Stock';
              }
            }
          }

          return productData['stock'] == 'Instock' ||
              productData['stock'] == 'In Stock';
        }
      }

      // Now check in own_shops_products
      final ownShopsQuery = await FirebaseFirestore.instance
          .collection('own_shops_products')
          .get();

      for (final shopDoc in ownShopsQuery.docs) {
        final productDoc = await FirebaseFirestore.instance
            .collection('own_shops_products')
            .doc(shopDoc.id)
            .collection(category)
            .doc(skuId)
            .get();

        if (productDoc.exists) {
          final productData = productDoc.data()!;
          print('Found in own_shops_products: $productData');

          if (productData['variants'] != null && variantWeight.isNotEmpty) {
            final variants = productData['variants'] as List;
            for (var variant in variants) {
              final v = variant as Map<String, dynamic>;
              if (v['volume'] == variantWeight) {
                return v['stock'] == 'Instock' || v['stock'] == 'In Stock';
              }
            }
          }

          return productData['stock'] == 'Instock' ||
              productData['stock'] == 'In Stock';
        }
      }

      print('Product not found in any shop');
      return false;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
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
    _cartSubscription?.cancel();
    super.dispose();
  }
}
