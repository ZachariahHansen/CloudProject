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
    final wsUrl = 'wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?user_id=$userId';
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    channel.stream.listen((message) {
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
      print('Failed to join lobby: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join lobby. Please try again.')),
      );
    }
  }

  Future<Map<String, dynamic>> createLobby(String name, int maxPlayers) async {
    final String apiUrl = baseUrl + 'lobbies';

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
                  onPressed: () => Navigator.of(context).pop(),
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
        onPressed: () => _showCreateLobbyDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Create Lobby',
      ),
    );
  }
}