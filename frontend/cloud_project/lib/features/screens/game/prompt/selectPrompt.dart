import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_project/features/screens/game/prompt/responsePrompt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web_socket_channel/web_socket_channel.dart';

class PromptSelectionPage extends StatefulWidget {
  final String gameId;
  
  const PromptSelectionPage({Key? key, required this.gameId}) : super(key: key);

  @override
  _PromptSelectionPageState createState() => _PromptSelectionPageState();
}

class _PromptSelectionPageState extends State<PromptSelectionPage> {
  String currentPrompt = "";
  bool isLoading = true;
  late String baseUrl;
  String errorMessage = "";
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadUrl();
    fetchPrompt();
    _initializeWebSocket();
  }

  Future<void> _loadUrl() async {
    try {
      final String response = await rootBundle.loadString('lib/features/url.json');
      final data = await json.decode(response);
      baseUrl = data['url'];
    } catch (e) {
      setState(() {
        errorMessage = "Error loading URL: $e";
      });
    }
  }

  Future<void> _initializeWebSocket() async {
    final storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'user_id');
    final wsUrl = 'wss://qs0x2ysrh6.execute-api.us-east-2.amazonaws.com/Prod?user_id=$userId';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel.stream.listen((message) {
      final data = json.decode(message);
      if (data['type'] == 'scenario_selected' && data['game_id'] == widget.gameId) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PromptResponsePage(
              gameId: widget.gameId,
            ),
          ),
        );
      }
    });
  }

  Map<String, dynamic> decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(resp);

    return payloadMap;
  }

  Future<void> fetchPrompt() async {
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

      final String apiUrl = baseUrl + 'games/${Uri.encodeComponent(widget.gameId)}/prompts/random';

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
          currentPrompt = data['prompt_text'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load prompt: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> confirmSelection() async {
    if (currentPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get a prompt first')),
      );
      return;
    }

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

    final String apiUrl = baseUrl + 'games/${Uri.encodeComponent(widget.gameId)}/prompts/submit';
    print('Submitting prompt to: $apiUrl');

    final requestBody = json.encode({
      'prompt_text': currentPrompt,  // Changed from 'prompt' to 'prompt_text'
    });
    print('Request body: $requestBody');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Prompt submitted successfully');
      // The WebSocket will handle navigation to the next page
    } else {
      final responseBody = json.decode(response.body);
      throw Exception('Failed to submit prompt: ${response.statusCode} ${response.reasonPhrase}\nServer message: ${responseBody['message']}');
    }
  } catch (e) {
    print('Error in confirmSelection: $e');
    setState(() {
      errorMessage = "Error submitting prompt: $e";
      isLoading = false;
    });
  }
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
        title: const Text('Prompt Selection'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  currentPrompt,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchPrompt,
                child: const Text('Get Another Prompt'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: confirmSelection,
                child: const Text('Confirm Selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}