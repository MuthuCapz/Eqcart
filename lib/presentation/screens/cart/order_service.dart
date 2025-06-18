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
    String couponValue = '',
    double deliveryTip = 0,
    required double subtotal,
    required double itemDiscount,
    required double deliveryFee,
    required double taxesCharges,
    required double giftPackingCharge,
  }) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 1. Fetch Cart
    DocumentSnapshot<Map<String, dynamic>> cartSnapshot =
        await firestore.collection('cart').doc(uid).get();

    if (!cartSnapshot.exists || cartSnapshot.data() == null) {
      throw Exception("Cart is empty!");
    }

    Map<String, dynamic> cartData = cartSnapshot.data()!;
    List<Map<String, dynamic>> cartItems = [];

    cartData.forEach((skuId, value) {
      var itemData = value[0]; // array with 0th item
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

    // 2. Generate Custom Order ID
    DocumentReference counterRef =
        firestore.collection('counters').doc('orders');
    int orderNumber = await firestore.runTransaction<int>((transaction) async {
      DocumentSnapshot counterSnap = await transaction.get(counterRef);

      int newOrderNumber;
      if (!counterSnap.exists) {
        newOrderNumber = 1000001;
        transaction.set(counterRef, {'lastOrderNumber': newOrderNumber});
      } else {
        int current = counterSnap['lastOrderNumber'];
        newOrderNumber = current + 1;
        transaction.update(counterRef, {'lastOrderNumber': newOrderNumber});
      }

      return newOrderNumber;
    });

    String orderId = 'ORD_$orderNumber';

    // 3. Store Order inside user -> orders subcollection
    DocumentReference orderRef = firestore
        .collection('orders')
        .doc(uid)
        .collection('orders')
        .doc(orderId);

    await orderRef.set({
      'orderId': orderId,
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
      'couponValue': couponValue,
      'deliveryTip': deliveryTip,
      'amountDetails': {
        'subtotal': subtotal,
        'itemDiscount': itemDiscount,
        'deliveryFee': deliveryFee,
        'taxesCharges': taxesCharges,
        'giftPacking': giftPackingCharge,
        'deliveryTip': deliveryTip,
        'total': orderTotal,
      },
    });

    // 4. Clear cart properly - delete each product field inside the cart document
    WriteBatch batch = firestore.batch();

    cartData.keys.forEach((skuId) {
      batch.update(firestore.collection('cart').doc(uid), {
        skuId: FieldValue.delete(),
      });
    });

    await batch.commit();
  }
}
