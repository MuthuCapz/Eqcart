import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../utils/colors.dart';
import '../main_category_content/ShopWiseCategoriesPage.dart';

class MatchedShopsPage extends StatelessWidget {
  const MatchedShopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _matchedShopIdsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final matchedShopIds = snapshot.data!;
        if (matchedShopIds.isEmpty) {
          return const Center(child: Text("No top-selling shops available."));
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _shopStream(matchedShopIds),
          builder: (context, shopSnapshot) {
            if (!shopSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final shops = shopSnapshot.data!;
            if (shops.isEmpty) {
              return const Center(
                  child: Text("No top-selling shops available."));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Big brands near you",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                // Use GridView.count instead of GridView.builder for simpler layout
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio:
                      1.9, // Adjust this for better card proportions
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  children: shops
                      .map((shop) => _buildShopCard(shop, context))
                      .toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, BuildContext context) {
    final isActive = shop['isActive'] == true;

    return AbsorbPointer(
      absorbing: !isActive, // disable touch if not active
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (isActive) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopCategoriesPage(
                      shopId: shop['shop_id'],
                      shopName: shop['shop_name'],
                    ),
                  ),
                );
              }
            },
            child: Opacity(
              opacity: isActive ? 1.0 : 0.5, // reduce opacity if inactive
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.green.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.green.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: shop['shop_logo'] ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.store,
                                size: 30, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              shop['shop_name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shop['description'] ?? 'Top rated shop',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 14, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    shop['city'] ?? '',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
          if (!isActive)
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Temporarily Closed",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Stream<List<String>> _matchedShopIdsStream() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final mapLocation = data['map_location'];
        if (mapLocation != null && mapLocation['isDefault'] == true) {
          final List<dynamic> ids = mapLocation['matched_shop_ids'] ?? [];
          return ids.map((id) => id.toString()).toList();
        }
      }
      return <String>[]; // no default address found
    });
  }

  Stream<List<Map<String, dynamic>>> _shopStream(List<String> matchedShopIds) {
    final shopQuery = FirebaseFirestore.instance.collection('shops');
    final ownShopQuery = FirebaseFirestore.instance.collection('own_shops');

    return Rx.combineLatest2(
      shopQuery.snapshots(),
      ownShopQuery.snapshots(),
      (QuerySnapshot shopSnap, QuerySnapshot ownShopSnap) {
        final allDocs = [...shopSnap.docs, ...ownShopSnap.docs];
        return allDocs
            .where((doc) => matchedShopIds.contains(doc.id))
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'shop_id': doc.id,
            'shop_name': data['shop_name'],
            'shop_logo': data['shop_logo'],
            'description': data['description'],
            'city': data['location']?['city'] ?? '',
            'isActive': data['isActive'] ?? false,
          };
        }).toList();
      },
    );
  }
}
