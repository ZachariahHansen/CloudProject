import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> getToken() async {
   final storage = FlutterSecureStorage();
  return await storage.read(key: 'jwt_token');
}

/**
  Future<void> makeAuthenticatedRequest() async {
  final token = await getToken();
  if (token == null) {
    // Handle the case where the token is not available
    return;
  }

  final response = await http.get(
    Uri.parse('https://your-api-endpoint.com'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  // Process the response
}
 */