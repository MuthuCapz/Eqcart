import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'current_location_update.dart';

class GoogleMapScreen extends StatefulWidget {
  final String userId;
  final String addressId;
  final Map<String, dynamic> addressData;
  final bool isEditMode;
  final String? originalLabel;

  const GoogleMapScreen({
    super.key,
    required this.userId,
    required this.addressId,
    required this.addressData,
    this.isEditMode = false,
    this.originalLabel,
  });

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late LocationProvider _provider;
  bool _isDisposed = false;
  @override
  void initState() {
    super.initState();
    _provider = LocationProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isEditMode) {
        _provider.initializeForEdit(
          widget.addressData,
          widget.isEditMode,
          widget.originalLabel ?? widget.addressId,
        );
      } else {
        _provider.getUserLocation();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _provider.disposeResources(); // Add this method to your LocationProvider
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: WillPopScope(
        onWillPop: () async {
          if (!_isDisposed) {
            _provider.disposeResources();
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => provider.notifyListeners(),
                      onSubmitted: (value) async {
                        if (value.isNotEmpty) {
                          FocusScope.of(context).unfocus();
                          await Future.delayed(
                              const Duration(milliseconds: 100));
                          await provider.searchPlaces(value);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        hintStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 14),
                        suffixIcon: provider.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.black),
                                onPressed: () {
                                  provider.searchController.clear();
                                  provider.notifyListeners();
                                },
                              )
                            : const Icon(Icons.search, color: Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          body: Consumer<LocationProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  // Map Section
                  Expanded(
                    flex: 6,
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        provider.setMapController(controller);
                        if (widget.isEditMode) {
                          final lat = widget.addressData['latitude'];
                          final lng = widget.addressData['longitude'];
                          if (lat != null && lng != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
                            );
                          }
                        } else if (provider.currentPosition != null) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(
                                provider.currentPosition!, 14),
                          );
                        }
                        provider.searchController.addListener(() {
                          if (provider.searchResults.isNotEmpty) {
                            provider.moveToSearchedLocation(
                                provider.searchResults.first, controller);
                          }
                        });
                      },
                      initialCameraPosition: CameraPosition(
                        target: widget.isEditMode &&
                                widget.addressData['latitude'] != null
                            ? LatLng(widget.addressData['latitude'],
                                widget.addressData['longitude'])
                            : provider.currentPosition ?? const LatLng(0, 0),
                        zoom: 14,
                      ),
                      markers: provider.markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      onTap: provider.onMapTapped,
                      onCameraMove: (position) =>
                          provider.onMapTapped(position.target),
                    ),
                  ),

                  // Address Input Section
                  Expanded(
                    flex: 8,
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Confirm your address",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),

                            // Address Display
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.green),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Consumer<LocationProvider>(
                                      builder: (context, provider, child) {
                                        // Show the passed address first, then selected address
                                        final displayAddress = widget.isEditMode
                                            ? (widget.addressData['address'] ??
                                                provider.selectedAddress ??
                                                "Address not found")
                                            : (provider.selectedAddress ??
                                                widget.addressData['address'] ??
                                                "Address not found");

                                        return Text(
                                          displayAddress,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Manual Address Input
                            const Text(
                              "Enter address manually",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: TextEditingController(
                                  text: widget.addressData['address'] ?? ''),
                              onChanged: (value) =>
                                  provider.setManualAddress(value),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 12),
                                hintText: "Enter address manually",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Label Selection
                            const Text(
                              "Save this address as",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLabelButton("Home", provider),
                                _buildLabelButton("Office", provider),
                                _buildLabelButton("Other", provider),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Confirm Button
                            ElevatedButton(
                              onPressed: () =>
                                  provider.confirmLocation(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabelButton(String label, LocationProvider provider) {
    bool isSelected = provider.addressLabel == label;
    return GestureDetector(
      onTap: () => provider.setAddressLabel(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
