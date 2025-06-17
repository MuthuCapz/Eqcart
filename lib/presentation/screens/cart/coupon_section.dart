import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';

class CouponSection extends StatefulWidget {
  final String shopId;

  const CouponSection({
    super.key,
    required this.shopId,
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

  @override
  void initState() {
    super.initState();
    _fetchCouponsForShop(widget.shopId);
  }

  Future<void> _fetchCouponsForShop(String shopId) async {
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
          // Skip this coupon if there's a date parsing error
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
          continue; // Skip if date parsing fails
        }

        if (!now.isAfter(from) || !now.isBefore(to)) continue;

        final List<dynamic> applicableShops = data['applicableShops'] ?? [];

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
            'validFrom': data['validFrom'],
            'validTo': data['validTo'],
          });
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
      });
    }
  }

  void _applyCoupon(String shopId) async {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('coupons_by_shops')
          .doc(couponCode);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        if (data['shopId'] == shopId) {
          final now = DateTime.now();
          final validFrom = (data['validFrom'] as Timestamp).toDate();
          final validTo = (data['validTo'] as Timestamp).toDate();

          if (now.isAfter(validFrom) && now.isBefore(validTo)) {
            setState(() {
              _appliedCoupon = data;
              showCouponField = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Coupon Applied: ${data['discount']}% off')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coupon is not active or expired')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon not valid for this shop')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid coupon code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error validating coupon: $e')),
      );
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
                  title: _appliedCoupon == null
                      ? const Text(
                          "Apply Coupon",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_appliedCoupon!['couponCode']} Applied",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "${_appliedCoupon!['discount'].toStringAsFixed(0)}% OFF",
                              style: const TextStyle(
                                  color: Colors.green, fontSize: 13),
                            ),
                          ],
                        ),
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
                          return Container(
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
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryColor,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Center(
                                        child: Text(
                                          "${(coupon['discount'] as num).toStringAsFixed(0)}% OFF",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(52, 16, 16, 16),
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
                                            color: Colors.black87),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setInnerState(() {
                                                showMore = !showMore;
                                              });
                                            },
                                            child: Text(
                                              showMore ? "Hide" : "+ MORE",
                                              style: TextStyle(
                                                color: AppColors.secondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _couponController.text =
                                                    coupon['couponCode'];
                                              });
                                              _applyCoupon(widget.shopId);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.secondaryColor,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text("APPLY"),
                                          )
                                        ],
                                      ),
                                      if (showMore)
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
                                                (coupon['validTo'] is Timestamp)
                                                    ? (coupon['validTo']
                                                            as Timestamp)
                                                        .toDate()
                                                    : DateTime.parse(
                                                        coupon['validTo']),
                                              )}\n"
                                              "- Applicable only for this shop\n"
                                              "- Other T&Cs may apply\n",
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                    ],
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
