import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> logout() async {
  final storage = FlutterSecureStorage();
  await storage.delete(key: 'jwt_token');
  await storage.delete(key: 'user_id');
  // Perform any other logout actions
}