import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_project/features/screens/lobby/lobbyScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;


class LobbyListPage extends StatefulWidget {
  const LobbyListPage({Key? key}) : super(key: key);

  @override
  _LobbyListPageState createState() => _LobbyListPageState();
}

class _LobbyListPageState extends State<LobbyListPage> {
  List<Map<String, dynamic>> lobbies = [];
  bool isLoading = true;
  String errorMessage = "";
  late String baseUrl;


  @override
  void initState() {
    super.initState();
    fetchLobbies();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<void> fetchLobbies() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final storage = FlutterSecureStorage();
    try {
      final String? token = await storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('JWT token not found');
      }

      final String apiUrl = baseUrl+'lobbies'; // Replace with your actual API endpoint
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          lobbies = List<Map<String, dynamic>>.from(data['lobbies']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load lobbies: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> joinLobby(String lobbyId) async {
    String apiUrl = baseUrl+'lobbies/$lobbyId/join'; 
    final storage = FlutterSecureStorage();

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await storage.read(key: 'jwt_token')}',
      },
    );
    
    Map<String, dynamic> responseData = jsonDecode(response.body);
    Map<String, dynamic> lobbyData = responseData['lobby'];

    // Implement lobby joining logic here
    // You'll need to make an API call to join the lobby
    print('Joining lobby with ID: $lobbyId');
    // After successful join, navigate to lobby page
    Navigator.push(context, MaterialPageRoute(builder: (context) => LobbyPage(lobbyData: lobbyData)));
  }

  Future<void> createLobby() async {
    // Implement lobby creation logic here
    // You'll need to make an API call to create a new lobby
    print('Creating new lobby');
    // After successful creation, refresh the lobby list
    await fetchLobbies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Lobbies'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: fetchLobbies,
                  child: ListView.builder(
                    itemCount: lobbies.length,
                    itemBuilder: (context, index) {
                      final lobby = lobbies[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(lobby['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Players: ${lobby['current_players']}/${lobby['max_players']}'),
                              Text('Status: ${lobby['status']}'),
                              Text('Created: ${DateTime.parse(lobby['created_at']).toLocal()}'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => joinLobby(lobby['id']),
                            child: Text('Join'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: createLobby,
        child: Icon(Icons.add),
        tooltip: 'Create Lobby',
      ),
    );
  }
}