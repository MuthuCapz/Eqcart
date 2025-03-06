import 'package:eqcart/Main/main_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  Set<Marker> _markers = {};

  String street = "";
  String city = "";
  String state = "";
  String zipcode = "";
  String fullAddress = "";

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentPosition = userLatLng;
      _selectedPosition = userLatLng;
      _markers.add(Marker(
        markerId: MarkerId("current_location"),
        position: userLatLng,
        infoWindow: InfoWindow(title: "Your Location"),
      ));
    });

    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: 14),
      ),
    );

    _fetchAddressFromLatLng(userLatLng);
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

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId("selected_location"),
        position: position,
        infoWindow: InfoWindow(title: "Selected Location"),
      ));
    });

    _mapController.animateCamera(CameraUpdate.newLatLng(position));

    _fetchAddressFromLatLng(position);
  }

  Future<void> _confirmLocation() async {
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
        .doc("address1")
        .set(addressData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location saved successfully!")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Map - Select Location")),
      body: Column(
        children: [
          Expanded(
            child: _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 14,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onTap: _onMapTapped,
                  ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _confirmLocation,
              child: Text("Confirm Location"),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocation,
        child: Icon(Icons.my_location),
      ),
    );
  }
}
