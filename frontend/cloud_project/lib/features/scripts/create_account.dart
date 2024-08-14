import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String apiUrl = 'https://3es48sls0c.execute-api.us-east-2.amazonaws.com/Prod'; // Replace with your actual API URL
  final storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/users/register'), // Adjust the endpoint if necessary
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email_address': email,
          'password': password,
          'is_admin': isAdmin,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Store the JWT token securely
        await storage.write(key: 'jwt_token', value: responseData['token']);
        await storage.write(key: 'user_id', value: responseData['Id']);

        return {
          'success': true,
          'message': responseData['message'],
          'userId': responseData['Id'],
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  Future<String?> getUserId() async {
    return await storage.read(key: 'user_id');
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_id');
  }
}