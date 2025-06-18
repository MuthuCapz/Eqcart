import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';

class CouponSection extends StatefulWidget {
  final String shopId;
  final double totalAmount;
  final Function(Map<String, dynamic>) onCouponApplied;
  final Function() onCouponRemoved;
  final Map<String, dynamic>? initialAppliedCoupon;

  const CouponSection({
    super.key,
    required this.totalAmount,
    required this.shopId,
    required this.onCouponApplied,
    required this.onCouponRemoved,
    this.initialAppliedCoupon,
  });

  @override
  State<CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<CouponSection> {
  bool showCouponField = false;
  final TextEditingController _couponController = TextEditingController();

  List<Map<String, dynamic>> _availableCoupons = [];
  bool _isLoadingCoupons = false;
  Map<String, dynamic>? _appliedCoupon;
  bool _initialLoadComplete = false;
  @override
  void initState() {
    super.initState();
    _appliedCoupon = widget.initialAppliedCoupon;
    if (!_initialLoadComplete) {
      _fetchCouponsForShop(widget.shopId);
    }
  }

  @override
  void didUpdateWidget(CouponSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the shopId changed or it's the initial load
    if (widget.shopId != oldWidget.shopId || !_initialLoadComplete) {
      _fetchCouponsForShop(widget.shopId);
    }
    if (widget.initialAppliedCoupon != oldWidget.initialAppliedCoupon) {
      setState(() {
        _appliedCoupon = widget.initialAppliedCoupon;
      });
    }
  }

  Future<void> _fetchCouponsForShop(String shopId) async {
    if (_initialLoadComplete) return;
    setState(() {
      _isLoadingCoupons = true;
    });

    final now = DateTime.now();
    final List<Map<String, dynamic>> allCoupons = [];

    try {
      // 1. Load from 'coupons_by_shops'
      final shopCouponSnapshot = await FirebaseFirestore.instance
          .collection('coupons_by_shops')
          .where('shopId', isEqualTo: shopId)
          .get();

      for (final doc in shopCouponSnapshot.docs) {
        final data = doc.data();
        DateTime from, to;

        try {
          from = (data['validFrom'] is Timestamp)
              ? (data['validFrom'] as Timestamp).toDate()
              : DateTime.parse(data['validFrom']);

          to = (data['validTo'] is Timestamp)
              ? (data['validTo'] as Timestamp).toDate()
              : DateTime.parse(data['validTo']);

          if (now.isAfter(from) && now.isBefore(to)) {
            allCoupons.add(data);
          }
        } catch (e) {
          continue;
        }
      }

      // 2. Load from general 'coupons' collection
      final generalCouponsSnapshot =
          await FirebaseFirestore.instance.collection('coupons').get();

      for (final doc in generalCouponsSnapshot.docs) {
        final data = doc.data();

        DateTime from, to;

        try {
          from = (data['validFrom'] is Timestamp)
              ? (data['validFrom'] as Timestamp).toDate()
              : DateTime.parse(data['validFrom']);

          to = (data['validTo'] is Timestamp)
              ? (data['validTo'] as Timestamp).toDate()
              : DateTime.parse(data['validTo']);
        } catch (e) {
          continue;
        }

        if (!now.isAfter(from) || !now.isBefore(to)) continue;

        // Check if coupon is common type or applies to this shop
        final couponType = data['type'] as String?;
        final List<dynamic> applicableShops = data['applicableShops'] ?? [];

        if (couponType == 'common') {
          // Common coupon - add without checking shops
          allCoupons.add({
            'couponCode': data['code'],
            'description': data['description'],
            'discount': data['discount'],
            'fixedAmount': data['fixedAmount']?.toDouble() ?? 0.0,
            'validFrom': data['validFrom'],
            'validTo': data['validTo'],
            'type': 'common',
          });
        } else {
          // Check if coupon applies to this shop
          final match = applicableShops.any((shopMap) {
            if (shopMap is Map<String, dynamic>) {
              return shopMap['id'] == shopId;
            }
            return false;
          });

          if (match) {
            allCoupons.add({
              'couponCode': data['code'],
              'description': data['description'],
              'discount': data['discount'],
              'fixedAmount': data['fixedAmount']?.toDouble() ?? 0.0,
              'validFrom': data['validFrom'],
              'validTo': data['validTo'],
              'type': data['type'],
            });
          }
        }
      }

      setState(() {
        _availableCoupons = allCoupons;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading coupons: $e")),
      );
    } finally {
      setState(() {
        _isLoadingCoupons = false;
        _initialLoadComplete = true;
      });
    }
  }

  void _applyCoupon(String shopId) async {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) return;

    try {
      // First check shop-specific coupons
      final shopCouponDoc = await FirebaseFirestore.instance
          .collection('coupons_by_shops')
          .doc(couponCode)
          .get();

      // If not found in shop coupons, check general coupons
      final couponQuery = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: couponCode)
          .limit(1)
          .get();

      DocumentSnapshot? couponDoc;
      Map<String, dynamic>? couponData;

      if (shopCouponDoc.exists) {
        couponDoc = shopCouponDoc;
        couponData = shopCouponDoc.data();
        if (couponData?['shopId'] != shopId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon not valid for this shop')),
          );
          return;
        }
      } else if (couponQuery.docs.isNotEmpty) {
        couponDoc = couponQuery.docs.first;
        couponData = couponDoc.data() as Map<String, dynamic>?;

        // Check if coupon is common type or applies to this shop
        final couponType = couponData?['type'] as String?;
        final applicableShops = couponData?['applicableShops'] as List? ?? [];

        if (couponType != 'common') {
          // For non-common coupons, check if it applies to this shop
          if (!applicableShops.any((shop) => shop['id'] == shopId)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coupon not valid for this shop')),
            );
            return;
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid coupon code')),
        );
        return;
      }

      // Validate coupon dates
      final now = DateTime.now();
      final validFrom = couponData!['validFrom'] is Timestamp
          ? (couponData['validFrom'] as Timestamp).toDate()
          : DateTime.parse(couponData['validFrom']);
      final validTo = couponData['validTo'] is Timestamp
          ? (couponData['validTo'] as Timestamp).toDate()
          : DateTime.parse(couponData['validTo']);

      if (now.isBefore(validFrom)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Coupon starts ${DateFormat('MMM d, y').format(validFrom)}')),
        );
        return;
      }

      if (now.isAfter(validTo)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon has expired')),
        );
        return;
      }

      // Check minimum order value
      final minOrderValue = couponData['minimumOrderValue']?.toDouble() ?? 0.0;
      if (minOrderValue > 0 && widget.totalAmount < minOrderValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Minimum order value of ₹$minOrderValue required')),
        );
        return;
      }

      // Validate discount values
      final fixedAmount = couponData['fixedAmount']?.toDouble() ?? 0.0;
      final discountPercentage = couponData['discount']?.toDouble() ?? 0.0;

      if (fixedAmount <= 0 && discountPercentage <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon has no valid discount value')),
        );
        return;
      }

      // Determine discount type and value
      final discountType = fixedAmount > 0 ? 'fixed' : 'percentage';
      final discountValue = fixedAmount > 0 ? fixedAmount : discountPercentage;

      // Create a consistent coupon data structure
      final appliedCouponData = {
        'code': couponData['couponCode'] ?? couponData['code'],
        'description': couponData['description'] ?? '',
        'discount': discountValue,
        'discountType': discountType,
        'fixedAmount': fixedAmount > 0 ? fixedAmount : 0,
        'percentage': fixedAmount > 0 ? 0 : discountPercentage,
        'minimumOrderValue': minOrderValue,
        'validFrom': couponData['validFrom'],
        'validTo': couponData['validTo'],
        'documentRef': couponDoc.reference.path,
      };

      // Apply the coupon
      setState(() {
        _appliedCoupon = appliedCouponData;
        showCouponField = false;
      });

      // Pass the complete coupon data to parent
      widget.onCouponApplied(appliedCouponData);

      final discountText = getCouponLabel(couponData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon Applied: $discountText')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying coupon: ${e.toString()}')),
      );
    }
  }

  String getCouponCode(Map<String, dynamic> coupon) {
    return coupon['code'] ?? coupon['couponCode'] ?? '';
  }

  String getCouponLabel(Map<String, dynamic> coupon) {
    final fixedAmount = (coupon['fixedAmount'] ?? 0).toDouble();
    final discount = (coupon['discount'] ?? 0).toDouble();

    if (fixedAmount > 0) {
      return 'FLAT ₹${fixedAmount.toStringAsFixed(0)} OFF';
    } else if (discount > 0) {
      return '${discount.toStringAsFixed(0)}% OFF';
    } else {
      return 'No Discount';
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponController.clear();
      showCouponField = false;
    });

    // Notify parent widget that coupon was removed
    widget.onCouponRemoved();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon removed')),
    );
  }

  bool _isCouponExpired(Map<String, dynamic> coupon) {
    try {
      final now = DateTime.now();
      final validTo = coupon['validTo'] is Timestamp
          ? (coupon['validTo'] as Timestamp).toDate()
          : DateTime.parse(coupon['validTo']);
      return now.isAfter(validTo);
    } catch (e) {
      return true; // If there's any error parsing dates, consider it expired
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoupons = _availableCoupons.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (!hasCoupons) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No coupons available now")),
          );
        }
      },
      child: AbsorbPointer(
        absorbing: !hasCoupons,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: hasCoupons ? 1.0 : 0.4,
          child: Container(
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
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_offer_outlined,
                        color: AppColors.secondaryColor),
                  ),
                  // Replace the current title in ListTile with:
                  title: _appliedCoupon == null
                      ? const Text(
                          "Apply Coupon",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              showCouponField = !showCouponField;
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_appliedCoupon!['code'] ?? _appliedCoupon!['couponCode']} Applied",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                _appliedCoupon!['discountType'] == 'fixed'
                                    ? 'FLAT ₹${_appliedCoupon!['discount'].toStringAsFixed(0)} OFF'
                                    : '${_appliedCoupon!['discount'].toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                  // In the ListTile within the build method, replace the current trailing with:
                  trailing: _appliedCoupon == null
                      ? IconButton(
                          icon: Icon(showCouponField
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down),
                          onPressed: () {
                            setState(() {
                              showCouponField = !showCouponField;
                            });
                          },
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _removeCoupon,
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              padding:
                                  EdgeInsets.zero, // Remove default padding
                              constraints:
                                  const BoxConstraints(), // Remove default constraints
                              iconSize: 24, // Set your preferred icon size
                            ),
                          ],
                        ),
                ),
                if (showCouponField) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _applyCoupon(widget.shopId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingCoupons)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_availableCoupons.isNotEmpty)
                    ..._availableCoupons.map((coupon) {
                      bool showMore = false;

                      return StatefulBuilder(
                        builder: (context, setInnerState) {
                          return // In the coupon list widget, replace the Container widget with:
                              Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Add this as the first child in the Stack to show expired overlay
                                if (_isCouponExpired(coupon))
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'EXPIRED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // The rest of your existing Stack children...
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: _isCouponExpired(coupon)
                                          ? Colors.grey
                                          : AppColors.secondaryColor,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Center(
                                        child: Text(
                                          coupon['fixedAmount'] != null &&
                                                  coupon['fixedAmount'] > 0
                                              ? 'FLAT ₹${coupon['fixedAmount'].toStringAsFixed(0)} OFF'
                                              : '${(coupon['discount'] as num).toStringAsFixed(0)}% OFF',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Add opacity to the content if expired
                                Opacity(
                                  opacity: _isCouponExpired(coupon) ? 0.6 : 1.0,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        52, 16, 16, 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          coupon['couponCode'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          coupon['description'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton(
                                              onPressed:
                                                  _isCouponExpired(coupon)
                                                      ? null
                                                      : () {
                                                          setInnerState(() {
                                                            showMore =
                                                                !showMore;
                                                          });
                                                        },
                                              child: Text(
                                                showMore ? "Hide" : "+ MORE",
                                                style: TextStyle(
                                                  color:
                                                      _isCouponExpired(coupon)
                                                          ? Colors.grey
                                                          : AppColors
                                                              .secondaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            _isCouponExpired(coupon)
                                                ? ElevatedButton(
                                                    onPressed: null,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.grey,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 20,
                                                          vertical: 10),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child:
                                                        const Text("EXPIRED"),
                                                  )
                                                : _appliedCoupon != null &&
                                                        (_appliedCoupon![
                                                                    'code'] ==
                                                                coupon[
                                                                    'couponCode'] ||
                                                            _appliedCoupon![
                                                                    'couponCode'] ==
                                                                coupon[
                                                                    'couponCode'])
                                                    ? ElevatedButton(
                                                        onPressed: null,
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 10),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                            "APPLIED"),
                                                      )
                                                    : ElevatedButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            _couponController
                                                                    .text =
                                                                coupon[
                                                                    'couponCode'];
                                                          });
                                                          _applyCoupon(
                                                              widget.shopId);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              AppColors
                                                                  .secondaryColor,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 10),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child:
                                                            const Text("APPLY"),
                                                      )
                                          ],
                                        ),
                                        if (showMore &&
                                            !_isCouponExpired(coupon))
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Divider(),
                                              const Text(
                                                "Terms and Conditions:",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "- Offer valid till ${DateFormat('MMMM d, y').format(
                                                  (coupon['validTo']
                                                          is Timestamp)
                                                      ? (coupon['validTo']
                                                              as Timestamp)
                                                          .toDate()
                                                      : DateTime.parse(
                                                          coupon['validTo']),
                                                )}\n"
                                                "${coupon['fixedAmount'] != null && coupon['fixedAmount'] > 0 ? '- Flat ₹${coupon['fixedAmount'].toStringAsFixed(0)} discount\n' : '- ${coupon['discount'].toStringAsFixed(0)}% discount\n'}"
                                                "- Other T&Cs may apply\n",
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
}
