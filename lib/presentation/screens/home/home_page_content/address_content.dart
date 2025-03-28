import '../../../../services/firebase_service.dart';

Stream<String?> addressStream() {
  String uid = FirebaseService.auth.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value("No user ID found");

  return FirebaseService.firestore
      .collection('users')
      .doc(uid)
      .collection('addresses')
      .snapshots()
      .map((snapshot) {
    try {
      for (var doc in snapshot.docs) {
        var data = doc.data();
        var mapLocation = data['map_location'] as Map<String, dynamic>?;

        if (mapLocation != null && mapLocation['isDefault'] == true) {
          String fullAddress = mapLocation['address'] ?? 'No address available';

          // Extract street and city
          List<String> parts = fullAddress.split(',');
          if (parts.length >= 3) {
            String street = parts[1].trim();
            String city = parts[2].trim();
            String formattedAddress = "$street, $city";

            if (formattedAddress.length > 33) {
              formattedAddress = formattedAddress.substring(0, 30) + "...";
            }

            return formattedAddress;
          }

          return fullAddress;
        }
      }
      return 'No default address found';
    } catch (e) {
      return 'Error fetching address: ${e.toString()}';
    }
  });
}
