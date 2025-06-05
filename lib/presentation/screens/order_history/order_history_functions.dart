import 'package:cloud_firestore/cloud_firestore.dart';

class OrderHistoryFunctions {
  // Fetch shop name and city from 'shops' or 'own_shops'
  static Future<Map<String, Map<String, dynamic>>> fetchAllShopDetails(
      List<DocumentSnapshot> orders) async {
    Map<String, Map<String, dynamic>> shopDetails = {};

    final shopIds = orders
        .map((order) => (order['items'] as List).isNotEmpty
            ? order['items'][0]['shopId']
            : null)
        .where((id) => id != null)
        .toSet();

    for (final shopId in shopIds) {
      for (final collection in ['shops', 'own_shops']) {
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(shopId)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          final settingsDoc = await FirebaseFirestore.instance
              .collection('${collection}_settings')
              .doc(shopId)
              .get();
          final settingsData = settingsDoc.data() ?? {};

          shopDetails[shopId] = {
            'shop_name': data['shop_name'] ?? 'Unknown Shop',
            'city': data['location']?['city'] ?? 'Unknown City',
            'shop_logo': data['shop_logo'],
            'cancelledTime': settingsData['cancelledTime'] ?? 0,
          };
          break;
        }
      }
    }
    return shopDetails;
  }
}
