import 'package:flutter/material.dart';
import 'package:cloud_project/models/webSockets.dart';
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
  List<String> _players = [];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    // Replace with your actual WebSocket URL
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://your-websocket-url.com/Prod?lobbyId=${widget.lobbyId}&userId=${widget.userId}'),
    );

    _channel.stream.listen((message) {
      final data = json.decode(message);
      if (data['type'] == 'playerList') {
        setState(() {
          _players = List<String>.from(data['players']);
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
                  return ListTile(
                    title: Text(_players[index]),
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