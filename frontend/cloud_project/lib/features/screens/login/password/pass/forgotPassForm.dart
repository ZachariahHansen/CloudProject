import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/login/loginScreen.dart';

class ForgotPassForm extends StatefulWidget {
  @override
  _ForgotPassFormState createState() => _ForgotPassFormState();
}

class _ForgotPassFormState extends State<ForgotPassForm> {
  final _passController = TextEditingController();
  final _repassController = TextEditingController();

  @override
  void dispose() {
    _passController.dispose();
    _repassController.dispose();
    super.dispose();
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
          height: 250,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
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
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _passController.text = value;
                    print('pass: $value');
                  });
                },
              ),
              SizedBox(height: 35),
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.fingerprint),
                  labelText: AutofillHints.password,
                  hintText: 'confirm password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: null,
                    icon: Icon(Icons.remove_red_eye_sharp),
                  ),
                ),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _repassController.text = value;
                    print('repass: $value');
                  });
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {
                  //TODOS: if login successful, if not give error message
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LogInPage()),
                    );
                }, child: Text('SUBMIT')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}