import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../home/main_page.dart';
import '../login/login_screen.dart';

import '../map/location_screen.dart';

class SplashScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/simple.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Centered Content with Button Slightly Lower
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 45),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    User? user = await _authService.getCurrentUser();
                    if (user != null) {
                      final uid = user.uid;
                      final addressSnapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('addresses')
                          .get();

                      if (addressSnapshot.docs.isNotEmpty) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainPage()),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LocationScreen()),
                        );
                      }
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.8),
                    shadowColor: Colors.transparent,
                    side: BorderSide(color: Colors.green, width: 2),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
