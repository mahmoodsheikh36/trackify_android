import 'package:flutter/material.dart';
import 'package:trackify_android/colors.dart';
import 'package:trackify_android/api.dart';

class FormTextField extends StatelessWidget {
  final String hintText;
  final FormFieldValidator<String> validator;

  FormTextField(this.hintText, this.validator);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: TextFormField(
        validator: this.validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: dimmerBgColor),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            borderSide: BorderSide(color: highlightedTextColor)),
        ),
      ),
    );
  }
}

class FormButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  FormButton(this.text, this.onPressed);

  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: this.onPressed,
      padding: EdgeInsets.all(10.0),
      child: Text(
        this.text,
        style: TextStyle(fontSize: 20)
      ),
      color: dimmerBgColor,
      splashColor: highlightedTextColor,
    );
  }
}

class LoginWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginWidgetState();
  }
}

class LoginWidgetState extends State<LoginWidget> {

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FormTextField('enter username', validateUsernameInput),
          FormTextField('enter password', validatePasswordInput),
          FormButton('Login', () { print('login...'); }),
        ],
      ),
    );
  }
}

class RegisterWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return RegisterWidgetState();
  }
}

class RegisterWidgetState extends State<RegisterWidget> {

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FormTextField('enter username', validateUsernameInput),
            FormTextField('enter password', validatePasswordInput),
            FormTextField('confirm password', validatePasswordInput),
            FormTextField('enter email', (value) {return null;}),
            FormButton('Register', () {
              if (_formKey.currentState.validate()) {
                Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('communicating with server..'))
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}