import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'current_location_update.dart';

class GoogleMapScreen extends StatefulWidget {
  final String label;

  const GoogleMapScreen({super.key, required this.label});

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  Set<String> existingLabels = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final labelToUse = widget.label.trim().isNotEmpty ? widget.label : "Home";
      final provider = Provider.of<LocationProvider>(context, listen: false);
      provider.getUserLocation();
      provider.setAddressLabel(labelToUse); // set selected tag
      _fetchExistingLabels();
    });
  }

  Future<void> _fetchExistingLabels() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .get();

    final labels = querySnapshot.docs.map((doc) => doc.id).toSet();

    setState(() {
      existingLabels = labels;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
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
                          FocusScope.of(context).unfocus(); // Dismiss keyboard
                          await Future.delayed(Duration(
                              milliseconds:
                                  100)); // Small delay to allow UI update
                          await provider.searchPlaces(value); // Trigger search
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        hintStyle: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(12)),
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
                                    fontSize: 18, fontWeight: FontWeight.bold),
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
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTagButton("Home", provider,
                                      existingLabels, widget.label),
                                  _buildTagButton("Office", provider,
                                      existingLabels, widget.label),
                                  _buildTagButton("Other", provider,
                                      existingLabels, widget.label),
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
    );
  }

  Widget _buildTagButton(
    String label,
    LocationProvider provider,
    Set<String> existingLabels,
    String passedLabel,
  ) {
    final bool isSelected = provider.addressLabel == label;
    final bool labelExistsInFirebase = existingLabels.contains(label);
    final bool isPassedLabel =
        passedLabel.trim().isNotEmpty && passedLabel == label;

    // If no label is passed, allow all; otherwise disable label if it exists and is not the passed one
    final bool isDisabled = passedLabel.trim().isNotEmpty &&
        labelExistsInFirebase &&
        !isPassedLabel;

    return GestureDetector(
      onTap: () {
        if (isDisabled) {
          Fluttertoast.showToast(
            msg: "Address with this label already exists",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          return;
        }

        if (isSelected) return;

        provider.setAddressLabel(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.2)
              : (isDisabled ? Colors.grey.withOpacity(0.3) : Colors.white),
          border: Border.all(
            color: isSelected
                ? Colors.green
                : (isDisabled ? Colors.grey : Colors.black26),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.green
                : (isDisabled ? Colors.grey : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
