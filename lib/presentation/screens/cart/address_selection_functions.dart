import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Fetches shop location and allowed user distance from Firestore
Future<Map<String, dynamic>> fetchShopAndSettings(String shopId) async {
  final shopDoc =
      await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
  final ownShopDoc = await FirebaseFirestore.instance
      .collection('own_shops')
      .doc(shopId)
      .get();

  GeoPoint? shopLocation;
  if (shopDoc.exists) {
    shopLocation = shopDoc.data()?['location'];
  } else if (ownShopDoc.exists) {
    shopLocation = ownShopDoc.data()?['location'];
  }

  final shopSettingDoc = await FirebaseFirestore.instance
      .collection('shops_setting')
      .doc(shopId)
      .get();
  final ownShopSettingDoc = await FirebaseFirestore.instance
      .collection('own_shops_setting')
      .doc(shopId)
      .get();

  double? allowedUserDistanceKm;
  if (shopSettingDoc.exists) {
    allowedUserDistanceKm =
        (shopSettingDoc.data()?['userDistance'] as num?)?.toDouble();
  } else if (ownShopSettingDoc.exists) {
    allowedUserDistanceKm =
        (ownShopSettingDoc.data()?['userDistance'] as num?)?.toDouble();
  }

  return {
    'shopLocation': shopLocation,
    'allowedUserDistanceKm': allowedUserDistanceKm,
  };
}

/// Dummy method: Replace with your logic

Future<List<Map<String, dynamic>>> fetchAllShopDetails(String userId) async {
  const String userId = 'y97BkXUaGCbItSFuHKxj3wXB9M62'; // Pass userId properly

  final cartDoc =
      await FirebaseFirestore.instance.collection('cart').doc(userId).get();

  if (!cartDoc.exists ||
      (cartDoc.data()?['productId'] as List?) == null ||
      (cartDoc.data()?['productId'] as List).isEmpty) {
    return [];
  }

  final firstProduct = (cartDoc.data()?['productId'] as List).first;
  final shopId = firstProduct['shopid'];

  // Fetch shop location
  final shopDoc =
      await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
  final ownShopDoc = await FirebaseFirestore.instance
      .collection('own_shops')
      .doc(shopId)
      .get();

  GeoPoint? shopLocation;
  if (shopDoc.exists) {
    shopLocation = shopDoc.data()?['location'];
  } else if (ownShopDoc.exists) {
    shopLocation = ownShopDoc.data()?['location'];
  }

  // Fetch shop settings
  final shopSettingDoc = await FirebaseFirestore.instance
      .collection('shops_setting')
      .doc(shopId)
      .get();
  final ownShopSettingDoc = await FirebaseFirestore.instance
      .collection('own_shops_setting')
      .doc(shopId)
      .get();

  double? allowedUserDistanceKm;
  if (shopSettingDoc.exists) {
    allowedUserDistanceKm =
        (shopSettingDoc.data()?['userDistance'] as num?)?.toDouble();
  } else if (ownShopSettingDoc.exists) {
    allowedUserDistanceKm =
        (ownShopSettingDoc.data()?['userDistance'] as num?)?.toDouble();
  }

  if (shopLocation == null || allowedUserDistanceKm == null) {
    return [];
  }

  return [
    {
      'shopLocation': shopLocation,
      'allowedUserDistanceKm': allowedUserDistanceKm,
    }
  ];
}

/// Calculates Haversine distance in KM between two geo points
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371; // km

  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}

/// Safely extract address text
String getAddressString(Map<String, dynamic> data) {
  if (data['map_location'] != null) {
    return data['map_location']['address'] ?? '';
  } else if (data['manual_location'] != null) {
    return data['manual_location']['address'] ?? '';
  }
  return '';
}

/// Safely extract GeoPoint of address
GeoPoint? getAddressLocation(Map<String, dynamic> data) {
  if (data['map_location'] != null) {
    return data['map_location']['lat_lng'];
  } else if (data['manual_location'] != null) {
    return data['manual_location']['lat_lng'];
  }
  return null;
}

/// Show error toast
void showErrorToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
