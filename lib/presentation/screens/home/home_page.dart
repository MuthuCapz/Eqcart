import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../utils/colors.dart';
import '../map/location_screen.dart';
import '../profile/profile_page.dart';

class HomeScreen extends StatelessWidget {
  Stream<Map<String, String>?> _addressStream() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        return {
          "street": data['street'] ?? '',
          "city": data['city'] ?? '',
        };
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Container(
          padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Map<String, String>?>(
                stream: _addressStream(),
                builder: (context, snapshot) {
                  String addressText = "Fetching address...";
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    addressText = "Loading...";
                  } else if (snapshot.hasError) {
                    addressText = "Error fetching address";
                  } else if (snapshot.hasData && snapshot.data != null) {
                    addressText =
                        "${snapshot.data?['street']}, ${snapshot.data?['city']}";
                  } else {
                    addressText = "No address found";
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Deliver to",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70)),
                          Row(
                            children: [
                              Text(addressText,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LocationScreen()),
                                  );
                                },
                                child: Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfilePage()),
                            );
                          }
                        },
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'Profile',
                            child: Text('Profile'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search food, groceries & more",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Welcome to Home Page!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
