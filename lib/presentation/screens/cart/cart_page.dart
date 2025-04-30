import 'package:eqcart/presentation/screens/home/main_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/colors.dart';
import 'add_tip_dialog.dart';

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

  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCartItems();
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

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // Cached Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item['image_url'] ?? '',
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (item['product_name'] ?? '').toString().length > 25
                                ? '${item['product_name'].toString().substring(0, 25)}...'
                                : item['product_name'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['variant_weight'] ?? '',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${(item['price'] ?? 0) * (item['quantity'] ?? 1)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    /// Quantity Selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 1, horizontal: 0),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(50), // Reduced border radius
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove,
                                size: 14), // Reduced icon size
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 10,
                                minHeight: 10), // Reduced button size
                            onPressed: () =>
                                updateQuantity(index, item['quantity'] - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${item['quantity']}',
                              style: const TextStyle(
                                  fontSize: 12), // Reduced text size
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add,
                                size: 14), // Reduced icon size
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 10,
                                minHeight: 10), // Reduced button size
                            onPressed: () =>
                                updateQuantity(index, item['quantity'] + 1),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmationDialog(index),
                    ),
                  ],
                ),
              ),
            );
          }),

          Column(
            children: [
              const SizedBox(height: 5),

              // Add More Products Button
              Padding(
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
                        child: Row(
                          mainAxisSize: MainAxisSize
                              .min, // important to keep button small
                          children: [
                            Icon(Icons.add, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Add More',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Coupon Section
              Container(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bill Summary

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Summary',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildBillRow('Subtotal', totalAmount),
                _buildBillRow('Delivery Fee', 25),
                _buildBillRow('Taxes & Charges', 10),
                _buildBillRow('Gift Packing Charge', 30),
                _buildBillRow(
                  'Delivery Tips',
                  deliveryTipAmount,
                  onTapTip: () async {
                    double? selectedTip = await showDialog(
                      context: context,
                      builder: (context) =>
                          AddTipDialog(initialTip: deliveryTipAmount),
                    );

                    if (selectedTip != null) {
                      setState(() {
                        deliveryTipAmount = selectedTip;
                      });
                    }
                  },
                ),
                const Divider(height: 24),
                _buildBillRow(
                    'Total', totalAmount + 25 + 10 + deliveryTipAmount,
                    isTotal: true),
              ],
            ),
          ),

          const SizedBox(height: 15), // Padding for bottom bar
        ],
      ),

      // Bottom Checkout Button
      bottomNavigationBar: Container(
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
          onPressed: () {},
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
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

          // Remove the key if list is empty
          if (productList.isEmpty) {
            updatedCartData.remove(skuKey);
          } else {
            updatedCartData[skuKey] = productList;
          }

          // Update Firestore
          await cartRef.set(updatedCartData);

          // Update local UI
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
}
