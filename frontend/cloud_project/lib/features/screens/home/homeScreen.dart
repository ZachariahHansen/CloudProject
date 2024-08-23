import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/lobby/lobbyListPage.dart';
import 'package:cloud_project/features/screens/lobby/lobbyScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatelessWidget {
  final storage = FlutterSecureStorage();
  late String baseUrl;

  Future<String> getUserId() async {
    final userId = await storage.read(key: 'user_id');
    if (userId == null) {
      throw Exception('User ID not found');
    }
    return userId;
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<Map<String, dynamic>> createLobby(String name, int maxPlayers) async {
  await _loadUrl();
  final String apiUrl = baseUrl+'lobbies';

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await storage.read(key: 'jwt_token')}',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'max_players': maxPlayers,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create lobby: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error creating lobby: $e');
  }
}

  void _showCreateLobbyDialog(BuildContext context) {
    String lobbyName = '';
    int maxPlayers = 2;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create Lobby'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Lobby Name'),
                    onChanged: (value) {
                      lobbyName = value;
                    },
                  ),
                  SizedBox(height: 20),
                  Text('Max Players: $maxPlayers'),
                  Slider(
                    value: maxPlayers.toDouble(),
                    min: 2,
                    max: 22,
                    divisions: 20,
                    label: maxPlayers.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        maxPlayers = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () async {
  if (lobbyName.isNotEmpty) {
    try {
      Map<String, dynamic> lobbyData = await createLobby(lobbyName, maxPlayers);
      final userId = await storage.read(key: 'user_id');
      
      if (userId != null) {
        Navigator.of(context).pop(); // Close the dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyPage(lobbyData: lobbyData),
          ),
        );
      } else {
        throw Exception('User ID not found');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating lobby: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a lobby name')),
    );
  }
},
                ),
                ElevatedButton(
                  child: Text('Create'),
                  onPressed: () async {
                    if (lobbyName.isNotEmpty) {
                      try {
                        var lobbyData = await createLobby(lobbyName, maxPlayers);
                        final userId = await storage.read(key: 'user_id');
                        
                        if (userId != null) {
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LobbyPage(lobbyData: lobbyData),
                            ),
                          );
                        } else {
                          throw Exception('User ID not found');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating lobby: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a lobby name')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

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
              onPressed: () => _showCreateLobbyDialog(context),
              child: Text('Create Lobby'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LobbyListPage()),
                );
              },
              child: Text('Join Lobby'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
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