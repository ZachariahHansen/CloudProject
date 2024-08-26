import 'package:cloud_project/features/screens/game/prompt/waitForPrompt.dart';
import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/game/prompt/selectPrompt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class LobbyPage extends StatefulWidget {
  final Map<String, dynamic> lobbyData;

  const LobbyPage({Key? key, required this.lobbyData}) : super(key: key);

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  late String lobbyId;
  late String lobbyName;
  late String creatorId;
  late int maxPlayers;
  late int currentPlayers;
  late String status;
  late List<String> playerIds;
  late String createdAt;
  late String baseUrl;
  
  List<Map<String, dynamic>> _players = [];
  String _username = '';
  final storage = FlutterSecureStorage();
  late WebSocketChannel _channel;
  String gameId = '';

  @override
  void initState() {
    super.initState();
    lobbyId = widget.lobbyData['id'] as String;
    lobbyName = widget.lobbyData['name'] as String;
    creatorId = widget.lobbyData['creator_id'] as String;
    maxPlayers = widget.lobbyData['max_players'] as int;
    currentPlayers = widget.lobbyData['current_players'] as int;
    status = widget.lobbyData['status'] as String;
    playerIds = (widget.lobbyData['players'] as List).cast<String>();
    createdAt = widget.lobbyData['created_at'] as String;
    _loadUrl().then((_) {
      _loadLobby();
      _initializeWebSocket();
    });
  }

  

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<void> _loadLobby() async {
    await fetchPlayers();
  }



  Future<void> _initializeWebSocket() async {
    final userId = await storage.read(key: 'user_id');
    final wsUrl = 'wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?user_id=$userId';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel.stream.listen((message) {
      print(message);
      final data = json.decode(message);
      if (data['type'] == 'lobby_update') {
        fetchPlayers();
      } else if (data['type'] == 'select_prompt' && data['game_id'] == gameId) {
        print('Received prompt selection message');
        _navigateToPromptSelection();
      }
      else if (data['type'] == 'waiting_for_prompt') {
        gameId = data['game_id'];
        print('Received leave lobby message');
        _navigateToWaitingPage();
      }
    });
  }

  Future<void> fetchPlayers() async {
    print("Fetching players");  
    final String? token = await storage.read(key: 'jwt_token');
    if (token == null) {
      throw Exception('JWT token not found');
    }

    final String apiUrl = '$baseUrl/lobbies/$lobbyId';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<String> updatedPlayerIds = List<String>.from(data['players']);
      
      List<Map<String, dynamic>> updatedPlayers = [];
      for (String playerId in updatedPlayerIds) {
        final playerData = await fetchPlayerData(playerId, token);
        updatedPlayers.add(playerData);
      }

      setState(() {
        playerIds = updatedPlayerIds;
        _players = updatedPlayers;
        currentPlayers = _players.length;
      });
    } else {
      throw Exception('Failed to load players: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> fetchPlayerData(String playerId, String token) async {
    final String apiUrl = '$baseUrl/users/$playerId';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'id': playerId, 'username': 'Unknown Player'};
    }
  }

  Future<void> _startGame() async {
    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('At least 2 players are required to start the game')),
      );
      return;
    }

    final String? token = await storage.read(key: 'jwt_token');
    if (token == null) {
      throw Exception('JWT token not found');
    }

    final String apiUrl = '$baseUrl/lobbies/$lobbyId/start';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Game started successfully: ${data['game_id']}');
        await storage.write(key: 'game_id', value: data['game_id']);
        gameId = data['game_id'];
        // The WebSocket will handle navigation to the prompt selection page
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only the lobby creator can start the game')),
        );
      } else {
        throw Exception('Failed to start game: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error starting game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start game. Please try again.')),
      );
    }
  }

  void _navigateToPromptSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PromptSelectionPage(gameId: gameId)),
    );
  }

  void _navigateToWaitingPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PromptWaitingPage(gameId: gameId)),
    );
  }

  void _leaveLobby() async {
    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      _channel.sink.add(json.encode({
        'action': 'leaveLobby',
        'lobbyId': lobbyId,
        'userId': userId,
      }));
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby: $lobbyName'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Card(
              margin: EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  return ListTile(
                    title: Text(player['username'] ?? 'Unknown Player'),
                    trailing: player['id'] == creatorId ? Text('(Creator)') : null,
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Max Players: $maxPlayers'),
                Text('Current Players: $currentPlayers'),
                Text('Status: $status'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _players.length >= 2 && creatorId == _players[0]['id'] ? _startGame : null,
                  child: Text('Start Game'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _leaveLobby,
                  child: Text('Leave Lobby'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
