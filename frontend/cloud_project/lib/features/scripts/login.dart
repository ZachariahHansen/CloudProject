import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginService {
  final String consulHost = 'consul';
  final int consulPort = 8500;
  final storage = FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    try {
      print("Username: $username");
      print("Password $password");
      final response = await http.post(
        Uri.parse('https://3es48sls0c.execute-api.us-east-2.amazonaws.com/Prod/users/login'),
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
        
        // Extract the token
        final String token = responseData['token'];
        
        // Save the token securely
        await storage.write(key: 'jwt_token', value: token);
        
        // Save the user_id if needed
        await storage.write(key: 'user_id', value: responseData['user_id']);
        
        return true;
      } else {
        print('Failed to login: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}