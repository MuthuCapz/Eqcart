import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'other_shop_product_add_dialog.dart';

class AddToCartButtons extends StatefulWidget {
  final String userId;
  final String productId;
  final String productName;
  final double price;
  final String imageUrl;
  final String variantKey; // Variant weight, such as '500g', '1kg'
  final String variantWeight; // Variant's specific weight (volume)
  final String shopId;
  final VoidCallback onCartUpdated;

  const AddToCartButtons({
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.variantKey,
    required this.variantWeight,
    required this.shopId,
    required this.onCartUpdated,
    Key? key,
  }) : super(key: key);

  @override
  State<AddToCartButtons> createState() => _AddToCartButtonsState();
}

class _AddToCartButtonsState extends State<AddToCartButtons> {
  int quantity = 0;
  bool _isLoading = true;
  String get _cartKey => "${widget.productId}_${widget.variantKey}";

  @override
  void initState() {
    super.initState();
    _loadCartQuantity();
  }

  Future<void> _loadCartQuantity() async {
    final cartRef =
        FirebaseFirestore.instance.collection('cart').doc(widget.userId);
    final docSnap = await cartRef.get();

    if (docSnap.exists) {
      final data = docSnap.data();
      final List<dynamic> productList = data?[widget.productId] ?? [];

      for (var item in productList) {
        if (widget.variantWeight.isNotEmpty &&
            item['variant_weight'] == widget.variantWeight) {
          quantity = item['quantity'] ?? 0;
          break;
        } else if (widget.variantKey.isNotEmpty &&
            item['variant'] == widget.variantKey) {
          quantity = item['quantity'] ?? 0;
          break;
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateFirestoreCart(int qty) async {
    final cartRef =
        FirebaseFirestore.instance.collection('cart').doc(widget.userId);
    final docSnap = await cartRef.get();
    Map<String, dynamic> currentData =
        Map<String, dynamic>.from(docSnap.data() ?? {});

    final List<dynamic> productList = currentData[widget.productId] ?? [];

    // Determine the identifier key (variant OR variant_weight)
    final String variantKeyName =
        widget.variantWeight.isNotEmpty ? 'variant_weight' : 'variant';
    final String variantKeyValue = widget.variantWeight.isNotEmpty
        ? widget.variantWeight
        : widget.variantKey;

    // Check if the variant already exists in the list
    int existingIndex = productList
        .indexWhere((element) => element[variantKeyName] == variantKeyValue);

    if (qty == 0) {
      // Remove if quantity is 0
      if (existingIndex != -1) {
        productList.removeAt(existingIndex);
      }
    } else {
      final variantData = {
        'product_name': widget.productName,
        'price': widget.price,
        'quantity': qty,
        'shopid': widget.shopId,
        'image_url': widget.imageUrl,
        variantKeyName: variantKeyValue,
      };

      if (existingIndex != -1) {
        productList[existingIndex] = variantData; // Update existing
      } else {
        productList.add(variantData); // Add new variant
      }
    }

    // Update or remove the entire product list
    if (productList.isEmpty) {
      currentData.remove(widget.productId);
    } else {
      currentData[widget.productId] = productList;
    }

    await cartRef.set(currentData);
    widget.onCartUpdated();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 36,
        width: 60,
        child: Center(
          child: SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ),
      );
    }

    return quantity == 0
        ? ElevatedButton(
            onPressed: () async {
              final cartRef = FirebaseFirestore.instance
                  .collection('cart')
                  .doc(widget.userId);
              final docSnap = await cartRef.get();
              Map<String, dynamic> currentData =
                  Map<String, dynamic>.from(docSnap.data() ?? {});

              bool isDifferentShop = false;

              for (var entry in currentData.entries) {
                List<dynamic> productVariants = entry.value as List<dynamic>;
                for (var variant in productVariants) {
                  if (variant['shopid'] != widget.shopId) {
                    isDifferentShop = true;
                    break;
                  }
                }
                if (isDifferentShop) break;
              }

              if (isDifferentShop) {
                bool? confirm = await showConfirmClearCartDialog(context);

                if (confirm == true) {
                  // User chose to proceed: clear cart and add new product
                  await cartRef.set({});
                  setState(() {
                    quantity = 1;
                  });
                  _updateFirestoreCart(1);
                }
                // else: Do nothing if cancelled
              } else {
                // Same shop or empty cart
                setState(() {
                  quantity = 1;
                });
                _updateFirestoreCart(1);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  if (quantity > 0) {
                    setState(() {
                      quantity--;
                    });
                    _updateFirestoreCart(quantity);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$quantity'),
              IconButton(
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                  _updateFirestoreCart(quantity);
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          );
  }
}
