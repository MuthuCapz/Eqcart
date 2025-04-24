import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../utils/colors.dart';
import 'ShopWiseCategoriesPage.dart';

class CategoryShopsPage extends StatefulWidget {
  final String categoryName;

  const CategoryShopsPage({Key? key, required this.categoryName})
      : super(key: key);

  @override
  _CategoryShopsPageState createState() => _CategoryShopsPageState();
}

class _CategoryShopsPageState extends State<CategoryShopsPage> {
  late Future<List<String>> _matchedShopIdsFuture;

  @override
  void initState() {
    super.initState();
    _matchedShopIdsFuture = _getMatchedShopIds();
  }

  Future<List<String>> _getMatchedShopIds() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final addressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .get();

    for (var doc in addressSnapshot.docs) {
      final data = doc.data();
      final mapLocation = data['map_location'];
      if (mapLocation != null && mapLocation['isDefault'] == true) {
        final List<dynamic> ids = mapLocation['matched_shop_ids'] ?? [];
        return ids.map((id) => id.toString()).toList();
      }
    }
    return [];
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
            .where((doc) =>
                matchedShopIds.contains(doc.id) &&
                doc['type'] == widget.categoryName)
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'shop_id': doc.id,
            'shop_name': data['shop_name'],
            'shop_logo': data['shop_logo'],
            'description': data['description'],
            'city': data['location']?['city'] ?? '',
          };
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(widget.categoryName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<String>>(
        future: _matchedShopIdsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final matchedShopIds = snapshot.data!;
          if (matchedShopIds.isEmpty) {
            return const Center(
              child: Text("No shops available for this category."),
            );
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
                    child: Text("No shops available for this category."));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: shops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return _buildShopTile(shop);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShopTile(Map<String, dynamic> shop) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopCategoriesPage(
                shopId: shop['shop_id'], shopName: shop['shop_name']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: shop['shop_logo'] ?? '',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.store),
                )),
            const SizedBox(width: 35),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop['shop_name'] ?? '',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor)),
                  const SizedBox(height: 6),
                  Text(
                    shop['description'] ?? 'No description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: AppColors.secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        shop['city'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
