import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_project/features/screens/game/prompt/responsePrompt.dart';

class PromptWaitingPage extends StatefulWidget {
  final String gameId;

  const PromptWaitingPage({Key? key, required this.gameId}) : super(key: key);

  @override
  _PromptWaitingPageState createState() => _PromptWaitingPageState();
}

class _PromptWaitingPageState extends State<PromptWaitingPage> {
  late WebSocketChannel _channel;
  final storage = FlutterSecureStorage();
  String _waitingMessage = 'Waiting for prompt selection...';

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    final userId = await storage.read(key: 'user_id');
    final wsUrl = 'wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?user_id=$userId';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel.stream.listen((message) {
      final data = json.decode(message);
      print(data);
      print(widget.gameId);
      if (data['type'] == 'scenario_selected' && data['game_id'] == widget.gameId) {
        print('Attempting to navigate to prompt response');
        _navigateToPromptResponse();
      } else if (data['type'] == 'prompt_selector_update' && data['game_id'] == widget.gameId) {
        setState(() {
          _waitingMessage = 'Waiting for ${data['selector_name']} to select a prompt...';
        });
      }
    });
  }

  void _navigateToPromptResponse() {
    Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PromptResponsePage(
              gameId: widget.gameId,
            ),
          ),
        );
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
        title: Text('Waiting for Prompt'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              _waitingMessage,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}