import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const MaterialApp(
    home: ManualLocationScreen(),
  ));
}

class ManualLocationScreen extends StatefulWidget {
  const ManualLocationScreen({super.key});

  @override
  State<ManualLocationScreen> createState() => _ManualLocationScreenState();
}

class _ManualLocationScreenState extends State<ManualLocationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _doorNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  String? _selectedAddressType;

  void _showSnackbar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAddressType == null) {
      _showSnackbar("Please select an address type.");
      return;
    }

    String street = _streetController.text.trim();
    String city = _cityController.text.trim();
    String pincode = _pincodeController.text.trim();
    String state = _stateController.text.trim();

    try {
      List<Location> locations =
          await locationFromAddress("$street, $city, $state, $pincode");

      if (locations.isEmpty) {
        _showSnackbar(
            "Invalid Address! Please enter a correct Street, City, State, and Pincode.");
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
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'door_no': _doorNoController.text.trim(),
        'street': street,
        'city': city,
        'pincode': pincode,
        'state': state,
        'latitude': latitude,
        'longitude': longitude,
        'address_type': _selectedAddressType,
        'createDateandTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Address saved successfully."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showSnackbar(
          "Invalid Address! Please enter a correct Street, City, State, and Pincode.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Address',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildTextField("Name", "Enter name", _nameController,
                        (value) {
                      if (value == null ||
                          value.length < 3 ||
                          value.length > 20) {
                        return "Name must be between 3-20 characters.";
                      }
                      return null;
                    }),
                    _buildTextField("Mobile Number", "Enter mobile number",
                        _mobileController, (value) {
                      if (value == null ||
                          !RegExp(r'^\d{10}$').hasMatch(value)) {
                        return "Enter a valid 10-digit mobile number.";
                      }
                      return null;
                    }),
                    _buildTextField("Door No (Optional)", "Enter door no",
                        _doorNoController, null),
                    _buildTextField(
                        "Street Name", "Enter street", _streetController,
                        (value) {
                      if (value == null ||
                          value.length < 3 ||
                          value.length > 50) {
                        return "Street must be 3-50 characters.";
                      }
                      return null;
                    }),
                    _buildTextField("City", "Enter city", _cityController,
                        (value) {
                      if (value == null || value.isEmpty || value.length > 30) {
                        return "City name is required and must be less than 30 characters.";
                      }
                      return null;
                    }),
                    _buildTextField(
                        "Pincode", "Enter pincode", _pincodeController,
                        (value) {
                      if (value == null ||
                          !RegExp(r'^\d{6}$').hasMatch(value)) {
                        return "Enter a valid 6-digit pincode.";
                      }
                      return null;
                    }),
                    _buildTextField("State", "Enter state", _stateController,
                        (value) {
                      if (value == null || value.isEmpty || value.length > 30) {
                        return "State name is required and must be less than 30 characters.";
                      }
                      return null;
                    }),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryButton(Icons.home, "Home"),
                        _buildCategoryButton(Icons.work, "Work"),
                        _buildCategoryButton(Icons.location_on, "Other"),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _saveAddress,
                child: const Text(
                  "Save Address",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange),
          ),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _selectedAddressType = label;
        });
      },
      icon: Icon(icon, color: Colors.orange),
      label: Text(label, style: const TextStyle(color: Colors.orange)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: _selectedAddressType == label
                ? Colors.orangeAccent
                : Colors.orange),
      ),
    );
  }
}
