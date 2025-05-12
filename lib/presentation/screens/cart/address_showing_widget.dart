import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import 'address_selection_bottom_sheet.dart';

class DefaultAddressWidget extends StatelessWidget {
  final String userId;

  const DefaultAddressWidget({Key? key, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No addresses found.');
        }

        String? address;
        String? defaultAddressId;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['map_location'] != null &&
              data['map_location']['isDefault'] == true) {
            address = data['map_location']['address'];
            defaultAddressId = doc.id;
            break;
          } else if (data['manual_location'] != null &&
              data['manual_location']['isDefault'] == true) {
            if (data['manual_location']['address'] != null) {
              address = data['manual_location']['address'];
              defaultAddressId = doc.id;
              break;
            }
          }
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
                          userId: userId,
                          initialSelectedAddressId: defaultAddressId,
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
