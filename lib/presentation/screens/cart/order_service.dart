import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  static Future<void> createOrder({
    required double orderTotal,
    required String paymentStatus,
    required String paymentMethod,
    required String shippingAddress,
    required Map<String, dynamic> deliveryDetails,
    String couponCode = '',
    double deliveryTip = 0,
  }) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    //  Fetch cart products
    DocumentSnapshot<Map<String, dynamic>> cartSnapshot =
        await firestore.collection('cart').doc(uid).get();

    if (!cartSnapshot.exists || cartSnapshot.data() == null) {
      throw Exception("Cart is empty!");
    }

    Map<String, dynamic> cartData = cartSnapshot.data()!;

    List<Map<String, dynamic>> cartItems = [];

    cartData.forEach((skuId, value) {
      var itemData =
          value[0]; // because inside each SKU, it's an array with 0th item
      cartItems.add({
        'productId': skuId,
        'productName': itemData['product_name'],
        'quantity': itemData['quantity'],
        'price': itemData['price'],
        'imageUrl': itemData['image_url'],
        'variantWeight': itemData['variant_weight'],
        'shopId': itemData['shopid'],
      });
    });

    //   Create Order
    DocumentReference orderRef =
        firestore.collection('orders').doc(); // Auto-ID

    await orderRef.set({
      'userId': uid,
      'orderStatus': 'pending',
      'orderTotal': orderTotal,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'orderDateTime': DateTime.now().toIso8601String(),
      'shippingAddress': shippingAddress,
      'deliveryDetails': deliveryDetails,
      'items': cartItems,
      'couponCode': couponCode,
      'deliveryTip': deliveryTip,
    });

    await firestore.collection('cart').doc(uid).delete();
  }
}
