import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/main_page.dart';

class LocationProvider extends ChangeNotifier {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  Set<Marker> _markers = {};

  String street = "";
  String city = "";
  String state = "";
  String zipcode = "";
  String fullAddress = "";

  LatLng? get currentPosition => _currentPosition;
  LatLng? get selectedPosition => _selectedPosition;
  Set<Marker> get markers => _markers;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentPosition = LatLng(position.latitude, position.longitude);
    _selectedPosition = _currentPosition;
    _updateMarker(_currentPosition!, "Your Location");
    _mapController
        ?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 14));
    _fetchAddressFromLatLng(_currentPosition!);
  }

  Future<void> _fetchAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String houseNumber = place.subThoroughfare ?? "";
        String streetName = place.thoroughfare ?? "";

        if (streetName.isEmpty) {
          streetName = place.subLocality ?? place.locality ?? "Unknown Street";
        }

        if (houseNumber.isNotEmpty) {
          street = "$houseNumber, $streetName";
        } else {
          street = streetName;
        }

        city = place.locality ?? place.subAdministrativeArea ?? "Unknown City";
        state = place.administrativeArea ?? "Unknown State";
        zipcode = place.postalCode ?? "000000";

        fullAddress = "$street, $city, $state, $zipcode";
      } else {
        print("Geocoding returned an empty list.");
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
  }

  void onMapTapped(LatLng position) {
    _selectedPosition = position;
    _updateMarker(position, "Selected Location");
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    _fetchAddressFromLatLng(position);
  }

  Future<void> confirmLocation(BuildContext context) async {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a location first")),
      );
      return;
    }

    if (street.isEmpty || city.isEmpty || state.isEmpty || zipcode.isEmpty) {
      print("Address fields are empty, retrying fetch...");
      await _fetchAddressFromLatLng(_selectedPosition!);
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;

    Map<String, dynamic> addressData = {
      "latitude": _selectedPosition!.latitude,
      "longitude": _selectedPosition!.longitude,
      "street": street,
      "city": city,
      "state": state,
      "zipcode": zipcode,
      "address": fullAddress,
      "isDefault": true,
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("addresses")
        .doc()
        .set(addressData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location saved successfully!")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  void _updateMarker(LatLng position, String title) {
    _markers.clear();
    _markers.add(Marker(
        markerId: MarkerId("selected_location"),
        position: position,
        infoWindow: InfoWindow(title: title)));
    notifyListeners();
  }
}
