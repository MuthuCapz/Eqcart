import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'current_location_update.dart';

class GoogleMapScreen extends StatefulWidget {
  final String? userId;
  final String? addressId;
  final Map<String, dynamic>? addressData;
  final double? initialLat;
  final double? initialLng;
  final bool isEditMode;
  final String? preSelectedLabel;

  const GoogleMapScreen({
    super.key,
    this.userId,
    this.addressId,
    this.addressData,
    this.initialLat,
    this.initialLng,
    this.isEditMode = false,
    this.preSelectedLabel,
  });

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late final LocationProvider locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      if (widget.initialLat != null && widget.initialLng != null) {
        locationProvider.setInitialLocation(
          latitude: widget.initialLat!,
          longitude: widget.initialLng!,
        );
      } else if (widget.addressData != null) {
        final manual = widget.addressData!['manual_location'];
        final map = widget.addressData!['map_location'];
        final lat = map?['latitude'] ?? manual?['latitude'];
        final lng = map?['longitude'] ?? manual?['longitude'];

        if (lat != null && lng != null) {
          locationProvider.setInitialLocation(
            latitude: lat,
            longitude: lng,
          );
        }
      } else {
        locationProvider.getUserLocation();
      }
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
                  return Center(
                    child: Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: provider.searchController,
                        textInputAction:
                            TextInputAction.search, // Set keyboard action
                        onChanged: (value) {
                          provider.notifyListeners(); // Update UI when typing
                        },
                        onSubmitted: (value) async {
                          if (value.isNotEmpty) {
                            FocusScope.of(context)
                                .unfocus(); // Dismiss keyboard
                            await Future.delayed(Duration(
                                milliseconds:
                                    100)); // Small delay to allow UI update
                            await provider
                                .searchPlaces(value); // Trigger search
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Search location...",
                          hintStyle: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 14),
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
