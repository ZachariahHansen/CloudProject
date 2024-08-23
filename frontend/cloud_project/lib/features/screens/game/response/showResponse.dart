import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  String? apiResponse;
  bool? survived;
  late String baseUrl;

  @override
  void initState() {
    super.initState();
    _loadUrl();
    _fetchEvaluation();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<void> _fetchEvaluation() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://your-api-endpoint.com/evaluate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_AUTH_TOKEN',
        },
        body: json.encode({
          'game_id': widget.gameId,
          'round_number': widget.roundNumber,
          'prompt': widget.prompt,
          'player_responses': [
            {
              'player_id': 'player1', // Assuming single player for now
              'response': widget.playerResponse,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          apiResponse = data['player_responses'][0]['evaluation']['explanation'];
          survived = data['player_responses'][0]['evaluation']['survived'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load evaluation');
      }
    } catch (e) {
      print('Error fetching evaluation: $e');
      setState(() {
        apiResponse = 'Failed to get evaluation. Please try again.';
        isLoading = false;
      });
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prompt:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.prompt,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your Response:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.playerResponse,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Evaluation:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    apiResponse ?? 'No evaluation available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    survived == null
                        ? 'Survival status unknown'
                        : survived!
                            ? 'You survived!'
                            : 'You did not survive.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: survived == null
                              ? Colors.grey
                              : survived!
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
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
    );
  }
}