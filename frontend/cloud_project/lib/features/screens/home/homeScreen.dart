import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Logic to create a lobby
                print("Create Lobby button pressed");
              },
              child: Text('Create Lobby'),
            ),
            SizedBox(height: 20), // Adds space between the buttons
            ElevatedButton(
              onPressed: () {
                // Logic to join a lobby
                print("Join Lobby button pressed");
              },
              child: Text('Join Lobby'),
            ),
            SizedBox(height: 20), // Adds space between the buttons
            ElevatedButton(
              onPressed: () {
                // Logic to logout
                print("Logout button pressed");
                // You might want to navigate to the login screen after logout
                Navigator.pop(context);
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
