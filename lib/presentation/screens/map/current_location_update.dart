import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/main_page.dart';

class LocationProvider with ChangeNotifier {
  String? selectedAddress;
  LatLng? currentPosition;
  Set<Marker> markers = {};

  String? manualAddress;
  String addressLabel = "Home"; // Default label
  TextEditingController searchController = TextEditingController();
  List<Location> searchResults = [];
  LocationProvider() {
    getUserLocation();
  }
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      notifyListeners();
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(query);
      searchResults = locations;
      notifyListeners();
    } catch (e) {
      print("Error searching for location: $e");
    }
  }

  void moveToSearchedLocation(
      Location location, GoogleMapController controller) {
    LatLng newPosition = LatLng(location.latitude, location.longitude);

    // Move the camera
    controller.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 14));

    // Update marker
    markers.clear();
    markers.add(Marker(
      markerId: MarkerId("searched"),
      position: newPosition,
    ));

    // Update address
    _updateAddress(newPosition);
    notifyListeners();
  }

  Future<void> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentPosition = LatLng(position.latitude, position.longitude);

      markers.clear();
      markers.add(Marker(
        markerId: MarkerId("current"),
        position: currentPosition!,
      ));

      await _updateAddress(currentPosition!);
      notifyListeners();
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  void setMapController(GoogleMapController controller) {}

  void onMapTapped(LatLng position) {
    currentPosition = position;
    markers.clear();
    markers.add(Marker(
      markerId: MarkerId("selected"),
      position: position,
    ));
    _updateAddress(position);
    notifyListeners();
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Avoid duplicate values
        String name = place.name ?? "";
        String street = place.street ?? "";

        if (name == street) {
          name = ""; // Remove duplicate entry
        }

        selectedAddress =
            "${name.isNotEmpty ? "$name, " : ""}${street.isNotEmpty ? "$street, " : ""}"
            "${place.subLocality}, ${place.locality}, ${place.administrativeArea} "
            "${place.postalCode}, ${place.country}";
      } else {
        selectedAddress = "Unknown location";
      }
    } catch (e) {
      selectedAddress = "Address not found";
    }
    notifyListeners();
  }

  void confirmLocation(BuildContext context) async {
    if (selectedAddress == null || selectedAddress == "Fetching address...") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a valid address.")),
      );
      return;
    }

    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not get your location.")),
      );
      return;
    }

    final userLat = currentPosition!.latitude;
    final userLng = currentPosition!.longitude;
    bool isDeliverable = false;

    try {
      final settingsData = [
        {
          "settingsCollection": "shops_settings",
          "shopCollection": "shops",
        },
        {
          "settingsCollection": "own_shops_settings",
          "shopCollection": "own_shops",
        }
      ];

      for (var config in settingsData) {
        final settingsSnap = await FirebaseFirestore.instance
            .collection(config["settingsCollection"]!)
            .get();

        for (var settingsDoc in settingsSnap.docs) {
          final shopId = settingsDoc.id;
          final userDistanceKm =
              (settingsDoc.data()["userDistance"] ?? 0).toDouble();

          final shopDoc = await FirebaseFirestore.instance
              .collection(config["shopCollection"]!)
              .doc(shopId)
              .get();

          if (!shopDoc.exists) continue;

          final location = shopDoc.data()?["location"];
          if (location == null ||
              location["latitude"] == null ||
              location["longitude"] == null) {
            continue;
          }

          final shopLat = location["latitude"];
          final shopLng = location["longitude"];

          final distanceInMeters = Geolocator.distanceBetween(
            userLat,
            userLng,
            shopLat,
            shopLng,
          );

          final distanceInKm = distanceInMeters / 1000;

          if (distanceInKm <= userDistanceKm) {
            isDeliverable = true;
            break;
          }
        }

        if (isDeliverable) break;
      }
    } catch (e) {
      print("Error checking delivery availability: $e");
    }

    if (isDeliverable) {
      await _storeAddressToFirestore(context);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      }
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Out of Delivery Area"),
            content:
                Text("Sorry, we do not deliver to your selected location."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              )
            ],
          ),
        );
      }
    }
  }

  Future<void> _storeAddressToFirestore(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection("users").doc(user.uid);
    final addressRef = userRef.collection("addresses");

    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Validate manual address before saving
    bool hasManualAddress = manualAddress != null && manualAddress!.isNotEmpty;
    double? manualLat, manualLng;

    if (hasManualAddress) {
      try {
        List<Location> locations = await locationFromAddress(manualAddress!);
        if (locations.isNotEmpty) {
          manualLat = locations.first.latitude;
          manualLng = locations.first.longitude;
        } else {
          throw Exception("Invalid Address");
        }
      } catch (e) {
        print("Invalid manual address: $e");
        // Show Toast instead of navigating
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Invalid address. Please check your address and try again.")),
          );
        }
        return; // Stop execution, do NOT navigate
      }
    }

    // Get all existing address documents
    final snapshot = await addressRef.get();

    // Ensure `isDefault` is false for all address types first
    for (var doc in snapshot.docs) {
      batch.update(addressRef.doc(doc.id), {
        "map_location.isDefault": false,
        "manual_location.isDefault": false,
      });
    }

    // Prepare data for the selected address type
    Map<String, dynamic> addressData = {
      "map_location": {
        "address": selectedAddress,
        "latitude": currentPosition?.latitude,
        "longitude": currentPosition?.longitude,
        "isDefault": true, // Make only this true
        "createDateTime": FieldValue.serverTimestamp(),
        "updateDateTime": FieldValue.serverTimestamp(),
      }
    };

    if (hasManualAddress) {
      addressData["manual_location"] = {
        "address": manualAddress,
        "latitude": manualLat,
        "longitude": manualLng,
        "isDefault": true, // Make only this true
        "createDateTime": FieldValue.serverTimestamp(),
        "updateDateTime": FieldValue.serverTimestamp(),
      };
    } else {
      addressData["manual_location"] = {"isDefault": true};
    }

    // Set data for the selected address type
    batch.set(
        addressRef.doc(addressLabel), addressData, SetOptions(merge: true));

    // Commit the batch write
    await batch.commit();

    // Navigate only if everything is valid
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  void setAddressLabel(String label) {
    addressLabel = label;
    notifyListeners();
  }

  void setManualAddress(String address) {
    manualAddress = address;
    notifyListeners();
  }
}
