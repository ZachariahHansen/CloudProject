import 'package:flutter/material.dart';
import 'package:cloud_project/models/webSockets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cloud_project/features/screens/game/prompt/selectPrompt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class LobbyPage extends StatefulWidget {
  final String lobbyId;
  final String userId;

  const LobbyPage({Key? key, required this.lobbyId, required this.userId}) : super(key: key);

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  late WebSocketChannel _channel;
  List<Map<String, String>> _players = [];
  String _username = '';
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _connectWebSocket();
  }

  Future<void> _loadUsername() async {
    final username = await storage.read(key: 'username');
    setState(() {
      _username = username ?? 'Unknown Player';
      _players.add({'id': widget.userId, 'name': _username});
    });
  }

  void _connectWebSocket() {
    // Replace with your actual WebSocket URL
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://g19wuss786.execute-api.us-east-2.amazonaws.com/Prod/@connect'),
    );

    _channel.stream.listen((message) {
      final data = json.decode(message);
      if (data['type'] == 'playerList') {
        setState(() {
          // Update the player list, but keep the current user
          _players = [
            {'id': widget.userId, 'name': _username},
            ...List<Map<String, String>>.from(data['players'])
                .where((player) => player['id'] != widget.userId)
          ];
        });
      }
    });
  }

  void _startGame() {
    // Implement game start logic
    _channel.sink.add(json.encode({
      'action': 'startGame',
      'lobbyId': widget.lobbyId,
    }));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PromptSelectionPage(gameId: widget.lobbyId)),
    );
  }

  void _leaveLobby() {
    // Implement leave lobby logic
    _channel.sink.add(json.encode({
      'action': 'leaveLobby',
      'lobbyId': widget.lobbyId,
      'userId': widget.userId,
    }));
    Navigator.of(context).pop(); // Return to previous screen
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
        title: Text('Lobby: ${widget.lobbyId}'),
      ),
      body: Row(
        children: [
          // Left side - Player list
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
                    trailing: player['id'] == widget.userId ? Text('(You)') : null,
                  );
                },
              ),
            ),
          ),
          // Right side - Buttons
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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