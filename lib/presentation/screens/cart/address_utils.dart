import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AddressUtils {
  static Future<bool> checkAddressDeliveryEligibility({
    required String shopId,
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      // Step 1: Get shop location from shops or own_shops
      DocumentSnapshot? shopDoc;
      String shopCollection = '';

      // Check in 'shops' collection
      shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();
      if (shopDoc.exists) {
        shopCollection = 'shops';
      } else {
        // Check in 'own_shops' collection
        shopDoc = await FirebaseFirestore.instance
            .collection('own_shops')
            .doc(shopId)
            .get();
        if (shopDoc.exists) {
          shopCollection = 'own_shops';
        } else {
          throw Exception("Shop not found.");
        }
      }

      final shopData = shopDoc.data() as Map<String, dynamic>?;
      if (shopData == null || shopData['location'] == null) {
        throw Exception("Shop location not found.");
      }

      final shopLocation = shopData['location'];
      double shopLatitude =
          (shopLocation['latitude'] as num?)?.toDouble() ?? 0.0;
      double shopLongitude =
          (shopLocation['longitude'] as num?)?.toDouble() ?? 0.0;

      // Step 2: Get userDistance from shops_settings or own_shops_settings
      DocumentSnapshot settingDoc = await FirebaseFirestore.instance
          .collection(shopCollection == 'shops'
              ? 'shops_settings'
              : 'own_shops_settings')
          .doc(shopId)
          .get();

      if (!settingDoc.exists) {
        throw Exception("Shop settings not found.");
      }

      final settingData = settingDoc.data() as Map<String, dynamic>?;
      if (settingData == null || settingData['userDistance'] == null) {
        throw Exception("User distance setting not found.");
      }

      double allowedDistanceKm;
      var userDistanceValue = settingData['userDistance'];

      if (userDistanceValue is num) {
        allowedDistanceKm = userDistanceValue.toDouble();
      } else if (userDistanceValue is String) {
        allowedDistanceKm = double.tryParse(userDistanceValue) ?? 0.0;
      } else {
        throw Exception("Invalid user distance format.");
      }

      // Step 3: Calculate distance
      double distanceInMeters = Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        shopLatitude,
        shopLongitude,
      );

      double distanceInKm = distanceInMeters / 1000;

      // Step 4: Compare distance
      if (distanceInKm <= allowedDistanceKm) {
        return true; // Address is eligible
      } else {
        throw Exception("Delivery not available to this location.");
      }
    } catch (e) {
      throw Exception("Error checking address eligibility: $e");
    }
  }
}
