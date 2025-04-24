import 'package:flutter/material.dart';

import '../../../utils/colors.dart';
import '../map/location_screen.dart';
import '../profile/profile_page.dart';
import 'home_page_content/address_content.dart';

import 'home_page_content/main_category_content/main_category_content.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Container(
          padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<String?>(
                stream: addressStream(),
                builder: (context, snapshot) {
                  String addressText = "Fetching address...";
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    addressText = "Loading...";
                  } else if (snapshot.hasError) {
                    addressText = "Error fetching address";
                  } else if (snapshot.hasData && snapshot.data != null) {
                    addressText = snapshot.data!;
                  } else {
                    addressText = "No address found";
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Deliver to",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70)),
                          Row(
                            children: [
                              Text(addressText,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LocationScreen()),
                                  );
                                },
                                child: Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Profile') {
                            addressStream().first.then((address) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                      address: address ?? "No address found"),
                                ),
                              );
                            });
                          }
                        },
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'Profile',
                            child: Text('Profile'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search food, groceries & more",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: HomeBody(),
    );
  }
}
