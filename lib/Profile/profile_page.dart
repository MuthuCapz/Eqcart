import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../splash_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  double _uploadProgress = 0.0;

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await Permission.photos.request();
    }
  }

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
    String fullPhoneNumber = "";
    TextEditingController phoneController = TextEditingController();
    bool isValid = false; // Flag to track validity

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Mobile Number"),
          content: Column(
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
                  isValid = phone.isValidNumber(); // Validate number
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                if (!isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Invalid phone number!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

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

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      print("No image selected.");
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("User is not logged in.");
        return;
      }

      File file = File(image.path);
      if (!file.existsSync()) {
        throw Exception("Selected file does not exist.");
      }

      String filePath = 'profile_pictures/${user.uid}.jpg';
      Reference storageRef = _storage.ref().child(filePath);

      print("Uploading file to: $filePath");

      UploadTask uploadTask = storageRef.putFile(file);

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
        });
        print("Upload progress: ${_uploadProgress * 100}%");
      });

      TaskSnapshot taskSnapshot = await uploadTask;

      print("Upload complete, fetching download URL...");

      // Wait until the file is actually uploaded before getting URL
      await Future.delayed(const Duration(seconds: 2));
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      print("Download URL received: $downloadUrl");

      // Update Firestore with the new profile picture URL
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'profile': downloadUrl});

      setState(() {
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated successfully!")),
      );
    } catch (e) {
      setState(() {
        _uploadProgress = 0.0;
      });

      print("Error uploading file: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          title: const Text("Logout",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to logout?",
              style: TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No",
                  style: TextStyle(fontSize: 18, color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _auth.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => SplashScreen()));
              },
              child: Text("Yes",
                  style: TextStyle(fontSize: 18, color: Colors.green[900])),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    Future.delayed(Duration.zero, _checkPhoneNumber);
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
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          // Safe extraction of user data
          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String profilePicUrl = userData['profile'] ?? '';
          String name = userData['name'] ?? 'N/A';
          String email = userData['email'] ?? 'N/A';
          String phone = userData['phone'] ?? 'N/A';

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user.uid)
                .collection('addresses')
                .limit(1)
                .snapshots(),
            builder: (context, addressSnapshot) {
              String address = 'N/A';
              if (addressSnapshot.hasData &&
                  addressSnapshot.data!.docs.isNotEmpty) {
                var addressData = addressSnapshot.data!.docs.first.data()
                    as Map<String, dynamic>;
                address =
                    "${addressData['street'] ?? 'N/A'}, ${addressData['city'] ?? 'N/A'}";
              }

              return Padding(
                padding: const EdgeInsets.all(30.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: profilePicUrl.isNotEmpty
                                  ? NetworkImage(profilePicUrl)
                                  : null,
                              child: profilePicUrl.isEmpty
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _updateProfilePicture,
                                child: const CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.edit,
                                      size: 18, color: Colors.orange),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      _buildProfileField('Name', name),
                      _buildProfileField('Email', email),
                      _buildProfileField('Phone', phone),
                      _buildProfileField('Address', address),
                      const SizedBox(height: 100),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _showLogoutConfirmationDialog,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text("Logout",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
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
          );
        },
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
