import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../utils/colors.dart';
import 'profile_ui.dart';
import 'profile_functions.dart';

class ProfilePage extends StatefulWidget {
  final String address;

  const ProfilePage({super.key, required this.address});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> _checkPhoneNumber() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    String? phone = userData?['phone'];

    if (phone == null || phone.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPhoneNumberDialog();
      });
    }
  }

  void _showPhoneNumberDialog() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String fullPhoneNumber = "";
    TextEditingController phoneController = TextEditingController();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Mobile Number"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter your mobile number to proceed."),
                const SizedBox(height: 10),
                IntlPhoneField(
                  controller: phoneController,
                  initialCountryCode: 'IN',
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (phone) {
                    fullPhoneNumber = phone.completeNumber;
                  },
                  validator: (phone) {
                    if (phone == null || !phone.isValidNumber()) {
                      return "Enter a valid phone number!";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                User? user = _auth.currentUser;
                if (user == null) return;

                await _firestore.collection('users').doc(user.uid).update({
                  'phone': fullPhoneNumber,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Phone number updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pop(context);
              },
              child:
                  const Text("Submit", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkPhoneNumber();
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.secondaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String profilePicUrl = userData['profile'] ?? '';
          String name = userData['name'] ?? 'N/A';
          String email = userData['email'] ?? 'N/A';
          String phone = userData['phone'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  buildProfilePicture(
                      profilePicUrl, () => updateProfilePicture(context)),
                  const SizedBox(height: 60),
                  buildProfileField('Name', name),
                  buildProfileField('Email', email),
                  buildProfileField('Phone', phone),
                  buildProfileField('Address', widget.address),
                  const SizedBox(height: 100),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => showLogoutConfirmationDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("Logout",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
