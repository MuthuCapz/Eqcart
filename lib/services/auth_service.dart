import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../presentation/screens/map/location_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user for splash screen
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Sign in with Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String formattedDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists) {
          await userDocRef.update({'updateDateTime': formattedDate});
        } else {
          await userDocRef.set({
            'email': user.email,
            'profile': user.photoURL ?? '',
            'name': user.displayName ?? '',
            'createDateTime': formattedDate,
            'updateDateTime': formattedDate,
          }, SetOptions(merge: true));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  }

  //Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Email/password login
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> registerAccount(BuildContext context) async {
    // ✅ Check if _formKey.currentState is null before calling validate()
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;
        String userId = userDoc.id;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'updateDateTime':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        });

        //  Ensure _auth is not null before using it
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        UserCredential newUserCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        User? newUser = newUserCredential.user;
        if (newUser != null) {
          String formattedDate =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

          await FirebaseFirestore.instance
              .collection('users')
              .doc(newUser.uid)
              .set({
            'email': email,
            'profile': '',
            'name': _usernameController.text.trim(),
            'password': password,
            'createDateTime': formattedDate,
            'updateDateTime': formattedDate,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
