import 'package:eqcart/Profile/profile_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MainPage', // Left side text
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(width: 15),
            IconButton(
              icon: Icon(Icons.menu, color: Colors.black), // Sidebar icon
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white38,
      ),
      body: const Center(
        child: Text(
          'Welcome to Eqcart!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
