import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart' show rootBundle;

class LoginService {
  final String consulHost = 'consul';
  final int consulPort = 8500;
  final storage = FlutterSecureStorage();
  String? baseUrl;

  LoginService() {
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final String response = await rootBundle.loadString('lib/features/url.json');
    final data = await json.decode(response);
    baseUrl = data['url'];
  }

  Future<int> login(String username, String password) async {
    if (baseUrl == null) {
      await _loadUrl();
    }
    print('Base URL: $baseUrl');
    try {
      print("Username: $username");
      print("Password: $password");
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Extract the token and other information
        final String token = responseData['token'];
        final String userId = responseData['user_id'];
        final bool isAdmin = responseData['is_admin'];
        
        // Save the token securely
        await storage.write(key: 'jwt_token', value: token);
        
        // Save the user_id
        await storage.write(key: 'user_id', value: userId);

        // Save the username
        await storage.write(key: 'username', value: username);

        // Save the is_admin status
        await storage.write(key: 'is_admin', value: isAdmin.toString());
        
        // Return 2 for admin, 1 for regular user
        if (isAdmin) {
          return 2;
        } else {
          return 1;
        }
      } else {
        print('Failed to login: ${response.statusCode}');
        return 0; // Return 0 for login failure
      }
    } catch (e) {
      print('Error: $e');
      return 0; // Return 0 for any errors
    }
  }
}