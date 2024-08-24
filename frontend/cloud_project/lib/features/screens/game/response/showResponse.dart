import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;

class PromptEvaluationPage extends StatefulWidget {
  final String gameId;
  final String prompt;
  final String playerResponse;
  final int roundNumber;

  const PromptEvaluationPage({
    Key? key,
    required this.gameId,
    required this.prompt,
    required this.playerResponse,
    required this.roundNumber,
  }) : super(key: key);

  @override
  _PromptEvaluationPageState createState() => _PromptEvaluationPageState();
}

class _PromptEvaluationPageState extends State<PromptEvaluationPage> {
  bool isLoading = true;
  String errorMessage = '';
  late String baseUrl;
  late WebSocketChannel channel;
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? gameResults;
  Map<String, String> usernames = {};

  @override
  void initState() {
    super.initState();
    _loadUrl().then((_) {
      _initializeWebSocket();
    });
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<void> _initializeWebSocket() async {
    final String? userId = await storage.read(key: 'user_id');
    final wsUrl = 'wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?user_id=$userId'; // Replace with your WebSocket URL
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    channel.stream.listen((message) {
      final data = json.decode(message);
      print(data);
      if (data['type'] == 'all_answers_submitted') {
        _fetchGameResults();
      }
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  Future<void> _fetchGameResults() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final String? token = await storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('JWT token not found');
      }

      final String apiUrl = baseUrl + 'games/${widget.gameId}/results';
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
          gameResults = data;
          isLoading = false;
        });
        _fetchUsernames();
      } else {
        throw Exception('Failed to load game results: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUsernames() async {
    final String? token = await storage.read(key: 'jwt_token');
    if (token == null) {
      throw Exception('JWT token not found');
    }

    for (var player in gameResults!['players']) {
      final String userId = player['id'];
      final String apiUrl = baseUrl + 'users/$userId';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          usernames[userId] = userData['username'];
        });
      }
    }
  }

  void _goToNextRound() {
    // TODO: Implement navigation to next round or game end
    Navigator.pushNamed(context, '/next-round');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Round ${widget.roundNumber} Results'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
              : gameResults == null
                  ? Center(child: Text('Waiting for all players to respond...'))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prompt:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              gameResults!['current_prompt'] ?? 'No prompt available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Player Responses:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 16),
                            ...gameResults!['players'].map<Widget>((player) {
                              return Card(
                                margin: EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        usernames[player['id']] ?? 'Unknown Player',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      SizedBox(height: 8),
                                      Text(player['response']),
                                      SizedBox(height: 8),
                                      Text(
                                        'Status: ${player['status']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: player['status'] == 'alive' ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            SizedBox(height: 24),
                            Center(
                              child: ElevatedButton(
                                onPressed: _goToNextRound,
                                child: Text('Next Round'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}