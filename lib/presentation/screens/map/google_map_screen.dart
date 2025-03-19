import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationProvider()..getUserLocation(),
      child: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text("Select or Add Your Address"),
              backgroundColor: Colors.white,
              elevation: 1,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: provider.currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      //Google Map
                      GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          provider.setMapController(controller);

                          // Move camera up slightly after loading
                          Future.delayed(Duration(milliseconds: 300), () {
                            controller.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(
                                  provider.currentPosition!.latitude - 0.0025,
                                  provider.currentPosition!.longitude,
                                ),
                              ),
                            );
                          });
                        },
                        initialCameraPosition: CameraPosition(
                          target: provider.currentPosition!,
                          zoom: 14,
                        ),
                        markers: provider.markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onTap: provider.onMapTapped,
                        onCameraMove: (position) {
                          provider.onMapTapped(position.target);
                        },
                      ),

                      //Center Marker
                      Positioned(
                        top: MediaQuery.of(context).size.height / 2 -
                            40, // Moves up
                        left: MediaQuery.of(context).size.width / 2 - 20,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Selected Location",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            Icon(Icons.location_on,
                                size: 40, color: Colors.red),
                          ],
                        ),
                      ),

                      //Floating GPS Button
                      Positioned(
                        top: 100,
                        right: 15,
                        child: FloatingActionButton(
                          onPressed: provider.getUserLocation,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.my_location, color: Colors.black),
                        ),
                      ),

                      //Bottom Address Input Section
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(30)),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //Confirm Address Title
                              Text(
                                "Confirm your address",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),

                              //Address Box
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
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 15),

                              //Enter address manually
                              Text(
                                "Enter Address Manually",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),
                              TextField(
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
                                    fontSize: 14, fontWeight: FontWeight.bold),
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
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTagButton(String label, LocationProvider provider) {
    return OutlinedButton(
      onPressed: () => provider.setAddressLabel(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.green, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: EdgeInsets.symmetric(horizontal: 33),
      ),
      child: Text(label, style: TextStyle(color: Colors.green)),
    );
  }
}

class LocationProvider with ChangeNotifier {
  LatLng? currentPosition;
  GoogleMapController? _mapController;
  Set<Marker> markers = {};
  String? selectedAddress;
  String addressLabel = "Home"; // Default label

  LocationProvider() {
    getUserLocation();
  }

  Future<void> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    currentPosition = LatLng(position.latitude, position.longitude);

    _updateAddress(currentPosition!);
    notifyListeners();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

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
        selectedAddress =
            "${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.administrativeArea}";
      } else {
        selectedAddress = "Unknown location";
      }
    } catch (e) {
      selectedAddress = "Address not found";
    }
    notifyListeners();
  }

  void setAddressLabel(String label) {
    addressLabel = label;
    notifyListeners();
  }

  void confirmLocation(BuildContext context) {
    if (selectedAddress != null) {
      print("Confirmed Address: $selectedAddress ($addressLabel)");
      Navigator.pop(
          context, {"address": selectedAddress, "label": addressLabel});
    }
  }
}
