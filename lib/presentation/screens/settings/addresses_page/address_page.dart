import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../map/current_location_update.dart';
import '../../map/google_map_screen.dart';
import '../../map/location_screen.dart';
import 'address_delete_dialogs.dart';
import 'address_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/colors.dart';

class AddressPage extends StatelessWidget {
  final String userId;

  const AddressPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("My Addresses"),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final addressDocs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: addressDocs.length,
                  itemBuilder: (context, index) {
                    final doc = addressDocs[index];
                    final label = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final manual = data['manual_location'] ?? {};
                    final map = data['map_location'] ?? {};
                    final isDefault =
                        manual['isDefault'] == true && map['isDefault'] == true;
                    final address =
                        manual['address'] ?? map['address'] ?? "No address";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              if (isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primaryColor.withOpacity(0.1),
                                    border: Border.all(
                                        color: AppColors.primaryColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Default",
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            address,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setDefaultAddress(
                                    userId: userId, selectedDocId: doc.id),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isDefault
                                            ? AppColors.primaryColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppColors.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: isDefault
                                          ? const Icon(Icons.check,
                                              size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("Set as Default"),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider(
                                            create: (_) => LocationProvider()
                                              ..getUserLocation(),
                                            child:
                                                GoogleMapScreen(label: label),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.edit_outlined,
                                        color: AppColors.secondaryColor),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      if (addressDocs.length <= 1) {
                                        Fluttertoast.showToast(
                                          msg:
                                              "Please add another address before deleting this one.",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          backgroundColor: Colors.black87,
                                          textColor: Colors.white,
                                        );
                                        return;
                                      }
                                      final confirm =
                                          await showDeleteConfirmationDialog(
                                              context);
                                      if (confirm) {
                                        await deleteAddress(
                                            userId: userId, docId: doc.id);
                                      }
                                    },
                                    icon: Icon(Icons.delete_outline,
                                        color: Colors.red.shade400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_location_alt_outlined,
                        color: Colors.white),
                    label: const Text(
                      "ADD NEW ADDRESS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
