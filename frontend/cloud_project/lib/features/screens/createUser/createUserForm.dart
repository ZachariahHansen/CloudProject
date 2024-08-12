import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/home/homeScreen.dart';
import 'package:cloud_project/features/screens/login/loginScreen.dart';
import 'package:cloud_project/features/scripts/create_account.dart';

class CreateUserForm extends StatefulWidget {
  @override
  _CreateUserFormState createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _repassController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _repassController.dispose();
    super.dispose();
  }

  bool get userValid {
    return _usernameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passController.text.isNotEmpty &&
        _repassController.text.isNotEmpty &&
        _passController.text == _repassController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          width: 900,
          height: 600,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_outlined),
                  labelText: AutofillHints.username,
                  hintText: 'username',
                  border: OutlineInputBorder(),
                ),
              ),
              
              SizedBox(height: 35),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  labelText: AutofillHints.email,
                  hintText: 'email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 35),
              TextFormField(
                controller: _passController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.fingerprint),
                  labelText: AutofillHints.password,
                  hintText: 'password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: null,
                    icon: Icon(Icons.remove_red_eye_sharp),
                  ),
                ),
              ),
              SizedBox(height: 35),
              TextFormField(
                controller: _repassController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.fingerprint),
                  labelText: AutofillHints.password,
                  hintText: 'confirm password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.remove_red_eye_sharp),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    String error = await validateUsername(_usernameController.text);
                    if (error.isEmpty) {
                      error = await validateEmail(_emailController.text);
                      if (error.isEmpty) {
                        error = validatePassword(_passController.text, _repassController.text);
                        if (error.isEmpty) {
                        }
                      }
                    }

                    if (error.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Text(error),
                            contentTextStyle: TextStyle(color: Colors.blue),
                          );
                        },
                      );
                    }
                  },
                  child: Text('SIGN UP'),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogInPage()),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account?",
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: ' Log In!',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


