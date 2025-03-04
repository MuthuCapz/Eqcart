import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eqcart/splash_screen.dart';
import '../Login/login_screen.dart';

void main() {
  runApp(const MaterialApp(
    home: ProfilePage(),
  ));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        backgroundColor: Colors.white38,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Eqcart!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 90),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      backgroundColor: Colors.white,
                      title: const Text(
                        "Logout",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        "Are you sure you want to logout?",
                        style: TextStyle(fontSize: 18),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "No",
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context); // Close dialog
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SplashScreen()),
                            );
                          },
                          child: Text(
                            "Yes",
                            style: TextStyle(
                                fontSize: 18, color: Colors.green[900]),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
