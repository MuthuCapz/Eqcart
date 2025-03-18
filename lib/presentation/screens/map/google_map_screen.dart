import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../utils/colors.dart';
import 'current_location_update.dart';

class GoogleMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationProvider()..getUserLocation(),
      child: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              title: Text("Google Map - Select Location"),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Column(
              children: [
                Expanded(
                  child: provider.currentPosition == null
                      ? Center(child: CircularProgressIndicator())
                      : GoogleMap(
                          onMapCreated: provider.setMapController,
                          initialCameraPosition: CameraPosition(
                            target: provider.currentPosition!,
                            zoom: 14,
                          ),
                          markers: provider.markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          onTap: provider.onMapTapped,
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  child: OutlinedButton(
                    onPressed: () => provider.confirmLocation(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryColor, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Confirm Location",
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}
