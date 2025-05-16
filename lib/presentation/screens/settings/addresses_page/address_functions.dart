import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteAddress({
  required String userId,
  required String docId,
}) async {
  final addressRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('addresses');

  final docSnapshot = await addressRef.doc(docId).get();

  if (!docSnapshot.exists) return;

  final data = docSnapshot.data()!;
  final wasDefault = (data['manual_location']?['isDefault'] == true) &&
      (data['map_location']?['isDefault'] == true);

  // Delete the selected address
  await addressRef.doc(docId).delete();

  // If the deleted one was default, set another address as default
  if (wasDefault) {
    final otherDocs = await addressRef.get();

    if (otherDocs.docs.isNotEmpty) {
      final newDefaultDocId = otherDocs.docs.first.id;

      await setDefaultAddress(
        userId: userId,
        selectedDocId: newDefaultDocId,
      );
    }
  }
}

Future<void> setDefaultAddress({
  required String userId,
  required String selectedDocId,
}) async {
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
