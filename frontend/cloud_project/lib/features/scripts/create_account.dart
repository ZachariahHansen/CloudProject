import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:html' as html;


Future<String> validateUsername(String username) async {
  if (username.isEmpty) {
    return "Please enter a value for username";
  }

  final response = await http.get(Uri.parse('http://localhost:80/user/get/username/$username'));

    if (response.statusCode == 404) {
      return "";
    }

    return "Username is already linked to an existing account";
}

Future<String> validateEmail(String email) async {
  RegExp expression = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  if (expression.hasMatch(email)) {
    final response = await http.get(Uri.parse('http://localhost:80/user/check/email/$email'));

    if (response.statusCode == 404) {
      return "";
    }

    return "email is already linked to an existing account";
  }

  return "Needs to be a valid email format example@example.com";
}

String validatePassword(String password, String confirmationPassword){
  RegExp expression = RegExp(r'^(?=.*[A-Z])(?=.*[0-9]).{8,}$');
  if(password == confirmationPassword) {
    if (expression.hasMatch(password)) {
      return "";
    }

    return "Password should contain at least one capital letter one number and be 8 characters in length";
  }
  
  return "Passwords don't match";
}

Future<bool> createAccount(String username, String dob, String email, String password) async {
  var uri = Uri.parse('http://localhost:80/user/post');
  var request = http.MultipartRequest('POST', uri);

  request.fields['username'] = username;
  request.fields['dob'] = dob.split(' ')[0];
  request.fields['email'] = email;
  request.fields['password'] = password;

  var response = await request.send();

  if (response.statusCode == 201) {
    var responseBody = await response.stream.bytesToString();
    html.window.localStorage["auth_token"] = responseBody;
    print("Response body: $responseBody");
    return true;
  } 

  print('Failed to create account: ${response.statusCode}');
  return false;
}