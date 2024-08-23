import 'package:flutter/material.dart';
import 'package:cloud_project/models/webSockets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cloud_project/features/screens/game/prompt/selectPrompt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
  late List<String> players;
  late String createdAt;
  late String baseUrl;
  
  late WebSocketChannel _channel;
  List<Map<String, String>> _players = [];
  String _username = '';
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    lobbyId = widget.lobbyData['id'];
    lobbyName = widget.lobbyData['name'];
    creatorId = widget.lobbyData['creator_id'];
    maxPlayers = widget.lobbyData['max_players'];
    currentPlayers = widget.lobbyData['current_players'];
    status = widget.lobbyData['status'];
    players = List<String>.from(widget.lobbyData['players']);
    createdAt = widget.lobbyData['created_at'];
    _loadUrl();
    _loadLobby();
    _connectWebSocket();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<void> _loadLobby() async {
    final username = await storage.read(key: 'username');
    final userId = await storage.read(key: 'user_id');
    setState(() {
      _username = username ?? 'Unknown Player';
      if (userId != null) {
        _players.add({'id': userId, 'name': _username});
      }
    });
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      // wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?userid={{userid}}
      Uri.parse('wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?userid=${creatorId}'),
    );

    _channel.stream.listen((message) {
      final data = json.decode(message);
      if (data['type'] == 'playerList') {
        setState(() {
          _players = [
            {'id': creatorId, 'name': _username},
            ...List<Map<String, String>>.from(data['players'])
                .where((player) => player['id'] != creatorId)
          ];
        });
      }
    });
  }

  void _startGame() {
    _channel.sink.add(json.encode({
      'action': 'startGame',
      'lobbyId': lobbyId,
    }));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PromptSelectionPage(gameId: lobbyId)),
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
                    title: Text(player['name'] ?? 'Unknown Player'),
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
                  onPressed: _startGame,
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