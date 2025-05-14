import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'address_utils.dart';

Future<void> updateDefaultAddress(String userId, String addressId) async {
  final userAddressRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('addresses');

  final batch = FirebaseFirestore.instance.batch();
  final snapshot = await userAddressRef.get();

  for (var doc in snapshot.docs) {
    final docRef = doc.reference;
    final isDefault = doc.id == addressId;
    batch.update(docRef, {
      'map_location.isDefault': isDefault,
      'manual_location.isDefault': isDefault,
    });
  }

  await batch.commit();
}

Future<void> handleAddressSelectionAndContinue({
  required BuildContext context,
  required String userId,
  required String selectedAddressId,
  required String? shopId,
  required VoidCallback onLoadingStart,
  required VoidCallback onLoadingEnd,
}) async {
  onLoadingStart();
  try {
    final selectedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(selectedAddressId)
        .get();

    if (!selectedDoc.exists) {
      _showAlert(context, "Address Not Found", "Selected address not found.");
      onLoadingEnd();
      return;
    }

    final addressData = selectedDoc.data() as Map<String, dynamic>;
    double? userLatitude;
    double? userLongitude;

    if (addressData['map_location'] != null) {
      userLatitude = addressData['map_location']['latitude'];
      userLongitude = addressData['map_location']['longitude'];
    } else if (addressData['manual_location'] != null) {
      userLatitude = addressData['manual_location']['latitude'];
      userLongitude = addressData['manual_location']['longitude'];
    }

    if (userLatitude == null || userLongitude == null) {
      _showAlert(
          context, "Coordinates Missing", "Address coordinates not available.");
      onLoadingEnd();
      return;
    }

    bool isEligible = await AddressUtils.checkAddressDeliveryEligibility(
      shopId: shopId ?? '',
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );

    if (isEligible) {
      await updateDefaultAddress(userId, selectedAddressId);
      Navigator.pop(context, selectedAddressId);
    } else {
      _showAlert(context, "Not Deliverable",
          "Selected address is out of delivery range.");
    }
  } catch (e) {
    _showAlert(context, "Error", e.toString().replaceFirst('Exception: ', ''));
  } finally {
    onLoadingEnd();
  }
}

void _showAlert(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off,
              size: 48,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              "Delivery Not Available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Delivery is not available to this address.\nPlease select other address or add new one.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
