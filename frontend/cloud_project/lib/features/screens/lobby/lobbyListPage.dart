import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/lobby/lobbyScreen.dart';

class LobbyListPage extends StatefulWidget {
  const LobbyListPage({Key? key}) : super(key: key);

  @override
  _LobbyListPageState createState() => _LobbyListPageState();
}

class _LobbyListPageState extends State<LobbyListPage> {
  List<Map<String, dynamic>> lobbies = [];

  @override
  void initState() {
    super.initState();
    fetchLobbies();
  }

  void fetchLobbies() {
    // TODO: Replace this with actual API call
    setState(() {
      lobbies = [
        {'id': '1', 'name': 'Lobby 1', 'players': 3, 'maxPlayers': 8},
        {'id': '2', 'name': 'Lobby 2', 'players': 5, 'maxPlayers': 8},
        {'id': '3', 'name': 'Lobby 3', 'players': 2, 'maxPlayers': 6},
      ];
    });
  }

  void joinLobby(String lobbyId) {
    // TODO: Implement lobby joining logic
    print('Joining lobby with ID: $lobbyId');
    // Navigate to lobby page or show a dialog
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Lobbies'),
      ),
      body: ListView.builder(
        itemCount: lobbies.length,
        itemBuilder: (context, index) {
          final lobby = lobbies[index];
          return ListTile(
            title: Text(lobby['name']),
            subtitle: Text('Players: ${lobby['players']}/${lobby['maxPlayers']}'),
            trailing: ElevatedButton(
              onPressed: () => joinLobby(lobby['id']),
              child: Text('Join'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          
                // Logic to join a lobby
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LobbyListPage()),
                );
          print('Create new lobby');
        },
        child: Icon(Icons.add),
        tooltip: 'Create Lobby',
      ),
    );
  }
}