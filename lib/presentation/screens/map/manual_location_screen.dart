import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

import '../../widgets/manual_location_text_field.dart';

import 'manual_location_update.dart';

class ManualLocationScreen extends StatefulWidget {
  const ManualLocationScreen({super.key});

  @override
  State<ManualLocationScreen> createState() => _ManualLocationScreenState();
}

class _ManualLocationScreenState extends State<ManualLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AddressController _controller = AddressController();

  String? _selectedAddressType;

  Future<void> _saveAddress() async {
    await _controller.saveAddress(context, _formKey, _selectedAddressType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Address',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.backgroundColor,
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
                    ManualLocationTextField(
                        "Name", "Enter name", _controller.nameController),
                    ManualLocationTextField("Mobile Number",
                        "Enter mobile number", _controller.mobileController),
                    ManualLocationTextField("Door No (Optional)",
                        "Enter door no", _controller.doorNoController),
                    ManualLocationTextField("Street Name", "Enter street",
                        _controller.streetController),
                    ManualLocationTextField(
                        "City", "Enter city", _controller.cityController),
                    ManualLocationTextField("Pincode", "Enter pincode",
                        _controller.pincodeController),
                    ManualLocationTextField(
                        "State", "Enter state", _controller.stateController),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CategoryButton(Icons.home, "Home", _selectedAddressType,
                            (type) {
                          setState(() => _selectedAddressType = type);
                        }),
                        CategoryButton(Icons.work, "Work", _selectedAddressType,
                            (type) {
                          setState(() => _selectedAddressType = type);
                        }),
                        CategoryButton(
                            Icons.location_on, "Other", _selectedAddressType,
                            (type) {
                          setState(() => _selectedAddressType = type);
                        }),
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
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _saveAddress,
                child: const Text("Save Address",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? selectedType;
  final Function(String) onSelect;

  const CategoryButton(this.icon, this.label, this.selectedType, this.onSelect,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => onSelect(label),
      icon: Icon(icon, color: AppColors.primaryColor),
      label: Text(label),
    );
  }
}
