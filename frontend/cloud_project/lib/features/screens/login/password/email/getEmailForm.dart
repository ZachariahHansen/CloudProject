import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/login/password/email/emailVerify.dart';

class GetEmailForm extends StatefulWidget {
  @override
  _GetEmailFormState createState() => _GetEmailFormState();
}

class _GetEmailFormState extends State<GetEmailForm> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
          height: 200,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.fingerprint),
                  labelText: AutofillHints.email,
                  hintText: 'email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _emailController.text = value;
                    print('email: $value');
                  });
                },
              ),
              SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => EmailVerify()),
                      );
                    },
                    child: Text('SEND CODE')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
