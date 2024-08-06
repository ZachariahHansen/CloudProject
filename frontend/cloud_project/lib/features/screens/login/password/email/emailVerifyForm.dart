import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/login/password/pass/forgotPass.dart';

class EmailVerifyForm extends StatefulWidget {
  @override
  _EmailVerifyFormState createState() => _EmailVerifyFormState();
}

class _EmailVerifyFormState extends State<EmailVerifyForm> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
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
          height: 180,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.numbers_rounded),
                  labelText: AutofillHints.oneTimeCode,
                  hintText: 'code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _codeController.text = value;
                    print('code: $value');
                  });
                },
              ),
              SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPass()),
                      );
                    },
                    child: Text('SUBMIT')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
