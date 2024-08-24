import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/game/response/showResponse.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PromptResponsePage extends StatefulWidget {
  final String gameId;

  const PromptResponsePage({
    Key? key,
    required this.gameId,
  }) : super(key: key);

  @override
  _PromptResponsePageState createState() => _PromptResponsePageState();
}

class _PromptResponsePageState extends State<PromptResponsePage> {
  final TextEditingController _responseController = TextEditingController();
  final int _maxCharacters = 200;
  late String baseUrl;
  String? currentPrompt;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUrl().then((_) => _fetchGameState());
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<void> _fetchGameState() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final storage = FlutterSecureStorage();
    try {
      final String? token = await storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('JWT token not found');
      }

      final String apiUrl = baseUrl + 'games/${Uri.encodeComponent(widget.gameId)}';
      
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
          currentPrompt = data['current_prompt'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load game state: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _submitResponse() async {
    final response = _responseController.text;
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a response')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final storage = FlutterSecureStorage();
    try {
      final String? token = await storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('JWT token not found');
      }

      final String apiUrl = baseUrl + 'games/${Uri.encodeComponent(widget.gameId)}/prompts/submit';
      
      final httpResponse = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'prompt_text': response,
        }),
      );

      if (httpResponse.statusCode == 200) {
        // Navigate to the next page on successful submission
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromptEvaluationPage(
              gameId: widget.gameId,
              prompt: currentPrompt ?? "No prompt available",
              playerResponse: response,
              roundNumber: 1, // You might want to fetch this from the game state
            ),
          ),
        );
      } else {
        throw Exception('Failed to submit prompt: ${httpResponse.statusCode} ${httpResponse.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error submitting prompt: $e";
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respond to Prompt'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Prompt:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentPrompt ?? 'No prompt available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your Response:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _responseController,
                        maxLength: _maxCharacters,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Type your response here...',
                          counterText: '${_responseController.text.length}/$_maxCharacters',
                        ),
                        onChanged: (text) {
                          setState(() {}); // Update the character count
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitResponse,
                        child: const Text('Submit Response'),
                      ),
                    ],
                  ),
                ),
    );
  }
}