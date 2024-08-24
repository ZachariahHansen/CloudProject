import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
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
  late WebSocketChannel channel;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUrl();
    _initializeWebSocket();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
    fetchLobbies();
  }

  Future<void> _initializeWebSocket() async {
    final String? userId = await storage.read(key: 'user_id');
    final wsUrl = 'wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?user_id=$userId'; // Replace with your WebSocket URL
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    channel.stream.listen((message) {
      // When a message is received, refresh the lobbies
      fetchLobbies();
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  Future<void> fetchLobbies() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final String? token = await storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('JWT token not found');
      }

      final String apiUrl = baseUrl + 'lobbies';
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
    String apiUrl = baseUrl + 'lobbies/$lobbyId/join';
    final String? token = await storage.read(key: 'jwt_token');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      Map<String, dynamic> lobbyData = responseData['lobby'];

      // Convert all values in lobbyData to the correct types
      lobbyData = {
        'id': lobbyData['id'] as String,
        'name': lobbyData['name'] as String,
        'creator_id': lobbyData['creator_id'] as String,
        'max_players': lobbyData['max_players'] as int,
        'current_players': lobbyData['current_players'] as int,
        'status': lobbyData['status'] as String,
        'players': (lobbyData['players'] as List).map((player) => player as String).toList(),
        'created_at': lobbyData['created_at'] as String,
      };

      Navigator.push(context, MaterialPageRoute(builder: (context) => LobbyPage(lobbyData: lobbyData)));
    } else {
      // Handle error
      print('Failed to join lobby: ${response.statusCode}');
      // You might want to show an error message to the user here
    }
  }


  Future<void> createLobby() async {
    // Implement lobby creation logic here
    print('Creating new lobby');
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
