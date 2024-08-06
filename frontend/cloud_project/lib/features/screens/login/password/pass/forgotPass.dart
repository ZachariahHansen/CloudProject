import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/login/password/pass/forgotPassForm.dart';

class ForgotPass extends StatelessWidget {
  const ForgotPass({Key? key}) : super(key: key);

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
                Text('Reset Password',
                    style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(height: 20),
                ForgotPassForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
