import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String apiUrl = 'https://3iqlyib94m.execute-api.us-east-2.amazonaws.com/Prod';
  final storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      // Validate inputs before making the API call
      String usernameError = await validateUsername(username);
      if (usernameError.isNotEmpty) {
        return {'success': false, 'message': usernameError};
      }

      String emailError = await validateEmail(email);
      if (emailError.isNotEmpty) {
        return {'success': false, 'message': emailError};
      }

      String passwordError = validatePassword(password, password); // Assuming password confirmation is the same
      if (passwordError.isNotEmpty) {
        return {'success': false, 'message': passwordError};
      }

      final response = await http.post(
        Uri.parse('$apiUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email_address': email,
          'password': password,
          'is_admin': isAdmin,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
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

  Future<String> validateUsername(String username) async {
    if (username.isEmpty) {
      return "Username cannot be empty";
    }
    if (username.length < 3) {
      return "Username must be at least 3 characters long";
    }
    // You might want to add an API call here to check if the username already exists
    return "";
  }

  Future<String> validateEmail(String email) async {
    if (email.isEmpty) {
      return "Email cannot be empty";
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return "Invalid email format";
    }
    // You might want to add an API call here to check if the email already exists
    return "";
  }

  String validatePassword(String password, String confirmPassword) {
    if (password.isEmpty) {
      return "Password cannot be empty";
    }
    if (password.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one uppercase letter";
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return "Password must contain at least one lowercase letter";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number";
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return "Password must contain at least one special character";
    }
    if (password != confirmPassword) {
      return "Passwords do not match";
    }
    return "";
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