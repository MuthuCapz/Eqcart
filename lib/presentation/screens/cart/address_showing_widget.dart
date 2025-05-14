import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import 'address_selection_bottom_sheet.dart';

class DefaultAddressWidget extends StatefulWidget {
  final String userId;
  final Function(String) onAddressSelected;

  const DefaultAddressWidget({
    Key? key,
    required this.userId,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<DefaultAddressWidget> createState() => _DefaultAddressWidgetState();
}

class _DefaultAddressWidgetState extends State<DefaultAddressWidget> {
  String? lastAddress;
  String? cachedAddress;

  Stream<Map<String, dynamic>> _combinedStream() {
    final cartStream = FirebaseFirestore.instance
        .collection('cart')
        .doc(widget.userId)
        .snapshots();
    final addressStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('addresses')
        .snapshots();

    return CombineLatestStream.combine2(
      cartStream,
      addressStream,
      (DocumentSnapshot cartSnap, QuerySnapshot addressSnap) {
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
        final hasData = snapshot.hasData && snapshot.data?['address'] != null;
        final address =
            hasData ? snapshot.data!['address'] as String : cachedAddress;
        final shopId = snapshot.data?['shopId'] as String?;
        final defaultAddressId = snapshot.data?['defaultAddressId'] as String?;

        if (hasData && address != lastAddress) {
          lastAddress = address;
          cachedAddress = address;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onAddressSelected(address!);
          });
        }

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
                          userId: widget.userId,
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
