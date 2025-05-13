import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'address_selection_bottom_sheet.dart';

class DefaultAddressWidget extends StatelessWidget {
  final String userId;

  const DefaultAddressWidget({Key? key, required this.userId})
      : super(key: key);

  Stream<Map<String, dynamic>> _combinedStream() {
    final cartStream =
        FirebaseFirestore.instance.collection('cart').doc(userId).snapshots();
    final addressStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots();

    return CombineLatestStream.combine2(
      cartStream,
      addressStream,
      (DocumentSnapshot cartSnap, QuerySnapshot addressSnap) {
        // Process cart
        String? shopId;
        if (cartSnap.exists) {
          final cartData = cartSnap.data() as Map<String, dynamic>? ?? {};
          if (cartData.isNotEmpty) {
            final firstProductKey = cartData.keys.first;
            final firstProduct = cartData[firstProductKey];
            if (firstProduct is List && firstProduct.isNotEmpty) {
              shopId = firstProduct[0]['shopid'] as String?;
            }
          }
        }

        // Process address
        String? address;
        String? defaultAddressId;

        for (var doc in addressSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['map_location'] != null &&
              data['map_location']['isDefault'] == true) {
            address = data['map_location']['address'];
            defaultAddressId = doc.id;
            break;
          } else if (data['manual_location'] != null &&
              data['manual_location']['isDefault'] == true) {
            address = data['manual_location']['address'];
            defaultAddressId = doc.id;
            break;
          }
        }

        return {
          'shopId': shopId,
          'address': address,
          'defaultAddressId': defaultAddressId,
        };
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _combinedStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Text('No address found.');
        }

        final data = snapshot.data!;
        final shopId = data['shopId'] as String?;
        final address = data['address'] as String?;
        final defaultAddressId = data['defaultAddressId'] as String?;

        if (address == null) {
          return const Text('No default address set.');
        }

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Text(
                    'Deliver to',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on,
                    color: AppColors.secondaryColor,
                  ),
                  title: Text(
                    address,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) => AddressSelectionBottomSheet(
                          userId: userId,
                          initialSelectedAddressId: defaultAddressId,
                          shopId: shopId,
                        ),
                      );
                    },
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
