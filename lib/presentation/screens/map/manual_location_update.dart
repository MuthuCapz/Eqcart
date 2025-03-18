import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

class AddressController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController doorNoController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  Future<void> saveAddress(BuildContext context, GlobalKey<FormState> formKey,
      String? addressType) async {
    if (!formKey.currentState!.validate()) return;

    if (addressType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an address type.")));
      return;
    }

    String street = streetController.text.trim();
    String city = cityController.text.trim();
    String pincode = pincodeController.text.trim();
    String state = stateController.text.trim();

    try {
      List<Location> locations =
          await locationFromAddress("$street, $city, $state, $pincode");

      if (locations.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Invalid Address!")));
        return;
      }

      Location location = locations.first;
      double latitude = location.latitude;
      double longitude = location.longitude;

      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference addressRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc();

      await addressRef.set({
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'door_no': doorNoController.text.trim(),
        'street': street,
        'city': city,
        'pincode': pincode,
        'state': state,
        'latitude': latitude,
        'longitude': longitude,
        'address_type': addressType,
        'createDateandTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Address saved successfully."),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid Address!")));
    }
  }
}
