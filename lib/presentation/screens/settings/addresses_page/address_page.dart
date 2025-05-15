import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/colors.dart';

class AddressPage extends StatelessWidget {
  final String userId;

  const AddressPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("My Addresses"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final addressDocs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: addressDocs.length,
                  separatorBuilder: (_, __) => const Divider(thickness: 1),
                  itemBuilder: (context, index) {
                    final doc = addressDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final manual = data['manual_location'] ?? {};
                    final map = data['map_location'] ?? {};
                    final isDefault =
                        manual['isDefault'] == true && map['isDefault'] == true;

                    final tag = manual['tag'] ?? map['tag'] ?? "Address";
                    final address =
                        manual['address'] ?? map['address'] ?? "No address";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isDefault,
                                  activeColor: AppColors.primaryColor,
                                  onChanged: (_) async {
                                    await setDefaultAddress(
                                        selectedDocId: doc.id);
                                  },
                                ),
                                const Text("Default Address"),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Open edit dialog or page
                                  },
                                  child: Text("Edit",
                                      style: TextStyle(
                                          color: AppColors.primaryColor)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Delete Address"),
                                        content: const Text(
                                            "Are you sure you want to delete this address?"),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Cancel")),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await deleteAddress(doc.id);
                                    }
                                  },
                                  child: Text("Delete",
                                      style: TextStyle(
                                          color: AppColors.primaryColor)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Add New Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Navigate to Add Address
                    },
                    icon: Icon(Icons.add, color: AppColors.primaryColor),
                    label: Text(
                      "ADD NEW",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> deleteAddress(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(docId)
        .delete();
  }

  Future<void> setDefaultAddress({required String selectedDocId}) async {
    final addressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses');

    final selectedDoc = addressRef.doc(selectedDocId);

    final all = await addressRef.get();
    for (final doc in all.docs) {
      await doc.reference.update({
        'manual_location.isDefault': false,
        'map_location.isDefault': false,
      });
    }

    await selectedDoc.update({
      'manual_location.isDefault': true,
      'map_location.isDefault': true,
    });

    // Optional: clear cart logic based on matched_shop_ids like before
    final selectedSnapshot = await selectedDoc.get();
    final selectedData = selectedSnapshot.data();
    if (selectedData == null) return;

    final manualLocation = selectedData['manual_location'] ?? {};
    final mapLocation = selectedData['map_location'] ?? {};

    final matchedShopIds = mapLocation['matched_shop_ids'] != null
        ? List<String>.from(mapLocation['matched_shop_ids'])
        : manualLocation['matched_shop_ids'] != null
            ? List<String>.from(manualLocation['matched_shop_ids'])
            : <String>[];

    final cartRef = FirebaseFirestore.instance.collection('cart').doc(userId);
    final cartDoc = await cartRef.get();
    if (!cartDoc.exists) return;

    final cartData = cartDoc.data()!;
    final batch = FirebaseFirestore.instance.batch();

    for (final entry in cartData.entries) {
      final productId = entry.key;
      final productArray = entry.value;

      if (productArray is List && productArray.isNotEmpty) {
        final productMap = productArray[0];
        if (productMap is Map<String, dynamic>) {
          final shopId = productMap['shopid'];
          if (shopId == null || !matchedShopIds.contains(shopId)) {
            batch.update(cartRef, {productId: FieldValue.delete()});
          }
        }
      }
    }

    await batch.commit();
  }
}
