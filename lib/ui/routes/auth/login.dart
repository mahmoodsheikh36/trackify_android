import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/api/auth.dart';
import 'package:trackify_android/ui/widgets/buttons.dart';
import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/ui/routes/auth/register.dart';
import 'package:trackify_android/ui/routes/general/general.dart';

class LoginRoute extends MyRoute {
  LoginRoute() : super(path: '/login');

  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Widget buildWidget(BuildContext context) {
    return SafeArea(child: Scaffold(
      backgroundColor: mainBlack,
      body: Form(
        key: _formKey,
        child: Container(child: ListView(
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
            SizedBox(height: 20,),
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
            SizedBox(height: 20,),
            Align(
              child: GeneralButton(
                text: 'Login',
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    //Scaffold.of(context).showSnackBar(
                    //  SnackBar(content: Text('logging in..'))
                    //);
                    bool success = await apiClient.authenticate(
                      usernameController.text, passwordController.text);
                    if (success) {
                      print('auth done!!!');
                      router.pushRoute(GeneralRoute());
                    } else {
                      print('no success in authentication');
                    }
                  } else {
                    print('login form not valid');
                  }
                }
              ),
              alignment: Alignment.center,
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('dont have an account?', style: highlightedTextStyle,),
                TextButton(
                  onPressed: () {
                    router.pushRoute(RegisterRoute());
                  },
                  child: Text('register')
                )
              ],
            )
          ],
        ), margin: EdgeInsets.all(20),),
      ),
    ));
  }
}
