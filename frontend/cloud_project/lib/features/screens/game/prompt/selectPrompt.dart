import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_project/features/screens/game/prompt/responsePrompt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  @override
  void initState() {
    super.initState();
    _loadUrl();
    fetchPrompt();
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

      // Decode and print JWT token contents
      try {
        final decodedToken = decodeJwt(token);
        print("Decoded JWT token:");
        print(json.encode(decodedToken));
        
        // Check expiration
        final exp = decodedToken['exp'];
        if (exp != null) {
          final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          final now = DateTime.now();
          print("Token expiration: $expirationDate");
          print("Current time: $now");
          if (expirationDate.isBefore(now)) {
            print("Warning: Token has expired");
          }
        }
      } catch (e) {
        print("Error decoding JWT token: $e");
      }

      final String apiUrl = baseUrl+'games/${Uri.encodeComponent(widget.gameId)}/prompts/random';
      print("API URL: $apiUrl");
      print("JWT Token: $token");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Response headers: ${response.headers}");
      print("Response body: ${response.body}");

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

  void confirmSelection() {
    if (currentPrompt.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PromptResponsePage(
            selectedPrompt: currentPrompt,
            gameId: widget.gameId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get a prompt first')),
      );
    }
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