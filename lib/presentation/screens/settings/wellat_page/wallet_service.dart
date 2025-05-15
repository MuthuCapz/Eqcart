import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Stream<double> walletBalanceStream() {
    final userId = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('walletData')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data()?['balance'] != null) {
        return (snapshot.data()?['balance'] as num).toDouble();
      } else {
        return 0.0;
      }
    });
  }

  static Future<void> updateBalance(double amount) async {
    final userId = _auth.currentUser!.uid;
    final walletRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc('walletData');

    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(walletRef);
      double current = 0.0;
      if (doc.exists) current = doc.data()?['balance'] ?? 0.0;

      tx.set(walletRef, {
        'balance': current + amount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }
}
