import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/game/response/showResponse.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class PromptResponsePage extends StatefulWidget {
  final String selectedPrompt;
  final String gameId;

  const PromptResponsePage({
    Key? key,
    required this.selectedPrompt,
    required this.gameId,
  }) : super(key: key);

  @override
  _PromptResponsePageState createState() => _PromptResponsePageState();
}

class _PromptResponsePageState extends State<PromptResponsePage> {
  final TextEditingController _responseController = TextEditingController();
  final int _maxCharacters = 200;
  late String apiUrl;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    apiUrl = data['url'];
  }

  void _submitResponse() {
    final response = _responseController.text;
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a response')),
      );
    } else {
      // Navigate to the next page
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PromptEvaluationPage(
      // TODO: replace each parameter with actual values
      gameId: 'your-game-id',
      prompt: "selectedPrompt",
      playerResponse: "response from user",
      roundNumber: 1,
    ),
  ),
);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respond to Prompt'),
      ),
      body: Padding(
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
              widget.selectedPrompt,
              style: Theme.of(context).textTheme.bodySmall,
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