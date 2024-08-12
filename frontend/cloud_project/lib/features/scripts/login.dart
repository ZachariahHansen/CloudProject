import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class LoginService {
  final String consulHost = 'consul';
  final int consulPort = 8500;
  // String? authToken =
  // 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6ImFiMmM0OGUyLTkxZWYtNGQ4YS1hOTllLWIyMDhiY2RiNWYxMiIsImV4cCI6MTcxNzA0MTUyN30.IWo3stQDkfJ6YMQEUOvr9c78WeO9-0OnhoyKXxqqQDM';

  // LoginService({required this.consulHost, required this.consulPort});

  Future<bool> login(String username, String password) async {
  return true; // TODO: Implement login
  }
  //   try {
  //     print("Username: $username");
  //     print("Password $password");
  //     final response = await http.post(
  //       Uri.parse('https://3es48sls0c.execute-api.us-east-2.amazonaws.com/Prod/users/login'),
  //       headers: {
  //           "Content-Type": "application/json"
  //           },
  //       body: jsonEncode({
  //         'username': username,
  //         'password': password,
  //       }),
  //     );

  //     print('Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       html.window.localStorage["session_id"] = response.body;
  //       // authToken = response.body;
  //       return true;
  //     } else {
  //       print('Failed to login: ${response.statusCode}');
  //       return false;
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //     return false;
  //   }
  // }

  // Future<String> getServiceAddress(String serviceName) async {
  //   // final url = Uri.http(consulHost, '$consulPort/v1/catalog/service/$serviceName');
  //   final url = Uri.http('localhost:80/user/login');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body) as List;
  //     if (body.isNotEmpty) {
  //       final service = body.first;
  //       return 'http://${service['ServiceAddress']}:${service['ServicePort']}';
  //     }
  //   }

  //   throw Exception('Failed to retrieve service address');
  // }
}
