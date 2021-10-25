import 'package:flutter/material.dart';

import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/ui/routes/auth/login.dart';
import 'package:trackify_android/static.dart';
import 'package:trackify_android/api/auth.dart';
import 'package:trackify_android/ui/widgets/buttons.dart';

class RegisterRoute extends MyRoute {
  RegisterRoute() : super(path: '/register');

  final _formKey = GlobalKey<FormState>();

  @override
  Widget buildWidget(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    return Form(
      key: _formKey,
      child: SafeArea(child: Scaffold(
        backgroundColor: mainBlack,
        body: Container(child: ListView(
          children: <Widget>[
            TextFormField(
              validator: (String username) {
                return validateUsernameInput(username);
              },
              controller: usernameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter username',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              validator: (String password) {
                return validatePasswordInput(password);
              },
              obscureText: true,
              controller: passwordController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter password',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              validator: (String confirmationPassword) {
                if (passwordController.text != confirmationPassword) {
                  return 'passwords dont match';
                }
                return null;
              },
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'confirm password',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              validator: (String email) {
                return validateEmailInput(email);
              },
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter email',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              child: GeneralButton(
                text: 'Register',
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(content: Text('communicating with server..'))
                    );
                    bool success = await apiClient.register(usernameController.text,
                      passwordController.text,
                      emailController.text);
                    if (success)
                    print('success in registeration');
                    else
                    print('no success in registeration');
                  }
                }
              ),
              alignment: Alignment.center,
            ),
            SizedBox(height: 20,),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('already have an account?', style: highlightedTextStyle),
              TextButton(onPressed: () {
                  router.pushRoute(LoginRoute());
              }, child: Text('login'))
            ],)
          ],
        ), margin: EdgeInsets.all(20),),
      )),
    );
  }
}
