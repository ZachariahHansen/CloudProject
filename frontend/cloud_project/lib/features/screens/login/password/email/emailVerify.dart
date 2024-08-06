import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/login/password/email/emailVerifyForm.dart';

class EmailVerify extends StatelessWidget {
  const EmailVerify({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.teal.shade100,
        body: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verify Code!',
                    style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(height: 20),
                EmailVerifyForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}