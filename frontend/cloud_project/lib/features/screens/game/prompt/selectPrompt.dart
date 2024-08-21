import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_project/features/screens/game/prompt/responsePrompt.dart';

class PromptSelectionPage extends StatefulWidget {
  final String gameId;

  const PromptSelectionPage({Key? key, required this.gameId}) : super(key: key);

  @override
  _PromptSelectionPageState createState() => _PromptSelectionPageState();
}

class _PromptSelectionPageState extends State<PromptSelectionPage> {
  List<String> prompts = [];
  int? selectedPromptIndex;
  bool isLoading = true;
  List<Map<String, dynamic>> prompts_json = [];
  String selectedPrompt = "";

  @override
  void initState() {
    super.initState();
    fetchPrompts();
  }

  Future<void> fetchPrompts() async {
    setState(() {
      isLoading = true;
    });

    prompts = [
    "You're stranded on a deserted island. How do you survive and signal for rescue?",
    "A time machine malfunctions, leaving you in the Middle Ages. How do you adapt and return to your time?",
    "An alien spaceship lands in your backyard. How do you communicate and handle the situation?"
  ];
  isLoading = false;

    // try {
    //   final response = await http.get(
    //     Uri.parse('https://your-api-endpoint.com/games/${widget.gameId}/prompts/random'),
    //     headers: {'Authorization': 'Bearer YOUR_AUTH_TOKEN'},
    //   );

    //   if (response.statusCode == 200) {
    //     final data = json.decode(response.body);
    //     setState(() {
    //       prompts = List<String>.from(data['prompts']);
    //       isLoading = false;
    //     });
    //   } else {
    //     throw Exception('Failed to load prompts');
    //   }
    // } catch (e) {
    //   print('Error fetching prompts: $e');
    //   setState(() {
    //     isLoading = false;
    //   });
    // }
  }

  void selectPrompt(int index) {
    setState(() {
      selectedPromptIndex = index;
      selectedPrompt = prompts[index];
    });
  }

  void confirmSelection() {
    if (selectedPromptIndex != null) {
      // TODO: Implement API call to submit the selected prompt
      print('Selected prompt: ${prompts[selectedPromptIndex!]}');
      // Navigate to the next page
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PromptResponsePage(
      selectedPrompt: selectedPrompt,
      // TODO: replace gameId later
      gameId: "123123",
    ),
  ),
);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a prompt')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Prompt'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: prompts.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => selectPrompt(index),
                        child: Card(
                          color: selectedPromptIndex == index
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              prompts[index],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: selectedPromptIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: confirmSelection,
                    child: const Text('Confirm Selection'),
                  ),
                ),
              ],
            ),
    );
  }
}