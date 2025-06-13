import 'dart:io';
import 'package:eqcart/presentation/screens/settings/help_center/query_accepted_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../utils/colors.dart';

class CustomQueryPage extends StatefulWidget {
  final String category;

  const CustomQueryPage({super.key, required this.category});

  @override
  State<CustomQueryPage> createState() => _CustomQueryPageState();
}

class _CustomQueryPageState extends State<CustomQueryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName =
          'query_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitQuery() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final username = user.displayName ?? 'Unknown';

      // Step 1: Get the latest document with the highest query_id
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_queries')
          .orderBy('query_id', descending: true)
          .limit(1)
          .get();

      int latestId = 10000; // Start from QRY_10001 if no data

      if (querySnapshot.docs.isNotEmpty) {
        final latestQueryId = querySnapshot.docs.first['query_id'];
        final numericPart =
            int.tryParse(latestQueryId.toString().replaceAll('QRY_', ''));
        if (numericPart != null) {
          latestId = numericPart;
        }
      }

      final newId = latestId + 1;
      final newQueryId = 'QRY_$newId';

      // Step 2: Save using custom doc ID
      await FirebaseFirestore.instance
          .collection('user_queries')
          .doc(newQueryId)
          .set({
        'query_id': newQueryId,
        'userId': user.uid,
        'email': user.email,
        'userName': username,
        'phone': user.phoneNumber,
        'category': widget.category,
        'message': _controller.text.trim(),
        'imageUrl': imageUrl,
        'status': "active",
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const QueryAcceptedPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong. Please try again later.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Submit Your Query',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: ${widget.category}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    maxLength: 500,
                    onChanged: (_) =>
                        setState(() {}), // Updates character counter
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.backgroundColor,
                      hintText: 'Describe your issue...',
                      counterText: '', // Hide default counter
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_controller.text.length}/500',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!,
                          height: 160, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondaryColor,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Attach Image (Optional)'),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitQuery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
