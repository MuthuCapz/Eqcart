import 'package:eqcart/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/main_page.dart';

class LocationProvider with ChangeNotifier {
  String? selectedAddress;
  LatLng? selectedLatLng;
  LatLng? currentPosition;
  Set<Marker> markers = {};
  String? manualAddress;
  String addressLabel = "Home"; // Default label
  TextEditingController searchController = TextEditingController();
  List<Location> searchResults = [];
  GoogleMapController? mapController;
  LocationProvider() {
    getUserLocation();
  }
  bool isLoading = false;
  bool _isInEditMode = false;
  Future<void> initializeForEdit(
      Map<String, dynamic> addressData, bool isEditMode, String label) async {
    _isInEditMode = isEditMode;
    isLoading = true;
    notifyListeners();

    // Set the label first
    addressLabel = label;

    if (addressData['latitude'] != null && addressData['longitude'] != null) {
      final latLng = LatLng(addressData['latitude'], addressData['longitude']);

      // Don't update currentPosition in edit mode
      selectedLatLng = latLng;

      markers.clear();
      markers.add(Marker(
        markerId: const MarkerId("selected"),
        position: latLng,
      ));

      // Set the address from the passed data first
      selectedAddress = addressData['address'];
      manualAddress = addressData['address'];

      // Then try to get more precise address from coordinates
      await _updateAddress(latLng);

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 14),
        );
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> getUserLocation() async {
    isLoading = true;
    notifyListeners();

    try {
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

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      currentPosition = LatLng(position.latitude, position.longitude);
      selectedLatLng = currentPosition;

      markers.clear();
      markers.add(Marker(
        markerId: const MarkerId("current"),
        position: currentPosition!,
      ));

      await _updateAddress(currentPosition!);
    } catch (e) {
      print("Error getting location: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

  Future<LatLng?> convertAddressToLatLng(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;
        return LatLng(lat, lng);
      }
    } catch (e) {
      print("Error converting address to LatLng: $e");
    }
    return null;
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  void onMapTapped(LatLng position) {
    if (_isInEditMode) {
      // Only update selectedLatLng in edit mode, not currentPosition
      selectedLatLng = position;
      markers.clear();
      markers.add(Marker(
        markerId: const MarkerId("selected"),
        position: position,
      ));
      _updateAddress(position);
    } else {
      // Normal behavior when not in edit mode
      currentPosition = position;
      selectedLatLng = position;
      markers.clear();
      markers.add(Marker(
        markerId: const MarkerId("selected"),
        position: position,
      ));
      _updateAddress(position);
    }
  }

  void disposeResources() {
    searchController.dispose();
    // Add any other cleanup needed for map controllers, etc.
    if (mapController != null) {
      mapController!.dispose();
      mapController = null;
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        selectedAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country
        ].where((part) => part != null && part.isNotEmpty).join(', ');
      }
    } catch (e) {
      print("Error updating address: $e");
      selectedAddress = "Address not found";
    }
    notifyListeners();
  }

  void confirmLocation(BuildContext context) async {
    if (selectedAddress != null) {
      LatLng? latLng = await convertAddressToLatLng(selectedAddress!);
      if (latLng != null) {
        print("Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}");
      }
    }

    final double userLat = selectedLatLng!.latitude;
    final double userLng = selectedLatLng!.longitude;
    List<String> matchedShopIds = [];

    final List<Map<String, String>> sourcePairs = [
      {
        "shopCollection": "shops",
        "settingCollection": "shops_settings",
      },
      {
        "shopCollection": "own_shops",
        "settingCollection": "own_shops_settings",
      },
    ];

    try {
      for (var source in sourcePairs) {
        final shopDocs = await FirebaseFirestore.instance
            .collection(source["shopCollection"]!)
            .get();

        for (var shopDoc in shopDocs.docs) {
          final shopData = shopDoc.data();
          final shopId = shopDoc.id;

          if (shopData["location"] == null ||
              shopData["location"]["latitude"] == null ||
              shopData["location"]["longitude"] == null) continue;

          final double shopLat = shopData["location"]["latitude"];
          final double shopLng = shopData["location"]["longitude"];

          final double distanceMeters =
              Geolocator.distanceBetween(userLat, userLng, shopLat, shopLng);
          final double distanceKm = distanceMeters / 1000;

          final settingDoc = await FirebaseFirestore.instance
              .collection(source["settingCollection"]!)
              .doc(shopId)
              .get();

          if (!settingDoc.exists || settingDoc["userDistance"] == null)
            continue;

          final dynamic rawUserDistance = settingDoc["userDistance"];
          final double userDistance = rawUserDistance is String
              ? double.tryParse(rawUserDistance) ?? 0
              : (rawUserDistance as num).toDouble();

          if (distanceKm <= userDistance) {
            matchedShopIds.add(shopId);
            print("Matched shop: $shopId - Distance: $distanceKm km");
          }
        }
      }

      if (matchedShopIds.isNotEmpty) {
        await _storeAddressToFirestore(context, matchedShopIds);
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
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFF2E9FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_pin,
                        color: AppColors.primaryColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Location not serviceable",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Our team is working tirelessly to bring 10 minute deliveries to your location",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "Try Changing Location",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Delivery range error: $e");
    }
  }

  Future<void> _storeAddressToFirestore(
      BuildContext context, List<String> matchedShopIds) async {
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
        "matched_shop_ids": matchedShopIds,
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

  LatLng? _pickedLocation;

  LatLng? get pickedLocation => _pickedLocation;
  void setInitialLocation(
      {required double latitude, required double longitude}) {
    _pickedLocation = LatLng(latitude, longitude);
    notifyListeners();
  }

  void setSelectedLatLng(LatLng latLng) {
    selectedLatLng = latLng;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
