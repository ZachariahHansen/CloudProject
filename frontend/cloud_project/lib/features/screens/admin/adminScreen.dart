import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;

class AdminPromptManagementPage extends StatefulWidget {
  @override
  _AdminPromptManagementPageState createState() => _AdminPromptManagementPageState();
}

class _AdminPromptManagementPageState extends State<AdminPromptManagementPage> {
  List<Map<String, dynamic>> prompts = [];
  String? selectedPromptId;
  final TextEditingController _newPromptController = TextEditingController();
  final storage = FlutterSecureStorage();
  String apiUrl = '';

  @override
  void initState() {
    super.initState();
    fetchPrompts();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    apiUrl = data['url'];
  }

  Future<void> fetchPrompts() async {
  try {
    final token = await storage.read(key: 'jwt_token');
    print('Fetching prompts with token: $token');
    
    final response = await http.get(
      Uri.parse(apiUrl+'admin/prompts'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        prompts = List<Map<String, dynamic>>.from(json.decode(response.body)['prompts']);
      });
    } else {
      print('Failed to fetch prompts. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Error fetching prompts: $e');
  }
}

  Future<void> addPrompt() async {
    if (_newPromptController.text.isEmpty) return;
    final token = await storage.read(key: 'jwt_token');
    print(token);
    print("string before post request");
    final response = await http.post(
      Uri.parse('https://3iqlyib94m.execute-api.us-east-2.amazonaws.com/Prod/admin/prompts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'text': _newPromptController.text}),
    );
    print("string after post request");
    if (response.statusCode == 201) {
      _newPromptController.clear();
      fetchPrompts();
    } 
    else if (response.statusCode == 401) {
      print('Authentication failed');
    }
    else {
      // Handle error
      print('Failed to add prompt');
    }
  }

  Future<void> deletePrompt() async {
    if (selectedPromptId == null) return;

    final token = await storage.read(key: 'jwt_token');
    final response = await http.delete(
      Uri.parse('https://3iqlyib94m.execute-api.us-east-2.amazonaws.com/Prod/admin/prompts/$selectedPromptId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        selectedPromptId = null;
      });
      fetchPrompts();
    } else {
      // Handle error
      print('Failed to delete prompt');
    }
  }

  void logout() async {
    await storage.delete(key: 'jwt_token');
    Navigator.of(context).pushReplacementNamed('/login'); // Adjust as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Prompt Management'),
      ),
      body: Row(
        children: [
          // Left side - Prompt list
          Expanded(
            flex: 1,
            child: Card(
              margin: EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: prompts.length,
                itemBuilder: (context, index) {
                  final prompt = prompts[index];
                  return ListTile(
                    title: Text(prompt['text']),
                    tileColor: selectedPromptId == prompt['id'] ? Colors.blue.withOpacity(0.3) : null,
                    onTap: () {
                      setState(() {
                        selectedPromptId = prompt['id'];
                      });
                    },
                  );
                },
              ),
            ),
          ),
          // Right side - Actions
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _newPromptController,
                    decoration: InputDecoration(
                      labelText: 'New Prompt',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: addPrompt,
                    child: Text('Add Prompt'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: deletePrompt,
                    child: Text('Delete Selected Prompt'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedPromptId = null;
                      });
                    },
                    child: Text('Deselect Prompt'),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: logout,
                    child: Text('Logout'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}