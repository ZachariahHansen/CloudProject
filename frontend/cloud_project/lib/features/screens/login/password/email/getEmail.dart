import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/login/password/email/getEmailForm.dart';

class GetEmail extends StatelessWidget {
  const GetEmail({Key? key}) : super(key: key);

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
                Text('Forget Password?',
                    style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(height: 20),
                GetEmailForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
