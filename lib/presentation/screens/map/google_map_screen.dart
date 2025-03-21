import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../home/main_page.dart';

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).getUserLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationProvider()..getUserLocation(),
      child: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: Consumer<LocationProvider>(
                builder: (context, provider, child) {
                  return Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors
                          .grey[300], // Darker background for better visibility
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: provider.searchController,
                      onChanged: (value) {
                        provider
                            .notifyListeners(); // Refresh UI to toggle the cancel icon
                      },
                      onSubmitted: (value) async {
                        if (value.isNotEmpty) {
                          await provider.searchPlaces(
                              value); // Trigger search and move the map
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        hintStyle: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        suffixIcon: provider.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.cancel, color: Colors.black),
                                onPressed: () {
                                  provider.searchController.clear();
                                  provider.notifyListeners();
                                },
                              )
                            : Icon(Icons.search, color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
            body: provider.currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Top Section - Google Map
                      Expanded(
                        flex:
                            6, // Increased proportionally to account for extra height
                        child: GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            provider.setMapController(controller);
                            provider.searchController.addListener(() {
                              if (provider.searchResults.isNotEmpty) {
                                provider.moveToSearchedLocation(
                                    provider.searchResults.first, controller);
                              }
                            });
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                  provider.currentPosition!, 14),
                            );
                          },
                          initialCameraPosition: CameraPosition(
                            target: provider.currentPosition!,
                            zoom: 14,
                          ),
                          markers: provider.markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          onTap: provider.onMapTapped,
                          onCameraMove: (position) {
                            provider.onMapTapped(position.target);
                          },
                        ),
                      ),

                      // Bottom Section - Address Input
                      Expanded(
                        flex:
                            8, // Adjusted to maintain balance with increased map height
                        child: SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 6)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Confirm your address",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),

                                // Address Box
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black26),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.green),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          provider.selectedAddress ??
                                              "Fetching address...",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 15),

                                //Enter address manually
                                Text(
                                  "Enter address manually",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                TextField(
                                  onChanged: (value) {
                                    provider.setManualAddress(
                                        value); // Store user input
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 12),
                                    hintText: "Enter address manually",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 15),

                                //  Save Address
                                Text(
                                  "Save this address as",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildTagButton("Home", provider),
                                    _buildTagButton("Office", provider),
                                    _buildTagButton("Other", provider),
                                  ],
                                ),
                                SizedBox(height: 20),

                                // Confirm Address Button
                                ElevatedButton(
                                  onPressed: () =>
                                      provider.confirmLocation(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                  child: Text(
                                    "Confirm address",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTagButton(String label, LocationProvider provider) {
    bool isSelected =
        provider.addressLabel == label; // Check if this button is selected

    return GestureDetector(
      onTap: () => provider.setAddressLabel(label),
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 12, horizontal: 30), // Adjust padding
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.2)
              : Colors.white, // Selected box is transparent green
          border: Border.all(
            color: isSelected
                ? Colors.green
                : Colors.grey, // Border changes on selection
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25), // Rounded corners
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.green
                : Colors.black, // Text color changes when selected
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal, // Bold for selected
          ),
        ),
      ),
    );
  }
}

class LocationProvider with ChangeNotifier {
  LatLng? currentPosition;
  Set<Marker> markers = {};
  String? selectedAddress;
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

    await _storeAddressToFirestore(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
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
