import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/lobby/lobbyListPage.dart';
import 'package:cloud_project/features/screens/lobby/lobbyScreen.dart';


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
                // Generate a unique lobby ID (you might want to use a more robust method)
                String lobbyId = DateTime.now().millisecondsSinceEpoch.toString();
                // Assume userId is available (you might need to pass this from a login screen)
                String userId = 'user123';
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LobbyPage(lobbyId: lobbyId, userId: userId),
                  ),
                );
                print("Create Lobby button pressed");
              },
              child: Text('Create Lobby'),
            ),
            SizedBox(height: 20), // Adds space between the buttons
            ElevatedButton(
              onPressed: () {
                // Logic to join a lobby
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LobbyListPage()),
                );
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
