import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';

class GeneralButton extends StatelessWidget {
  String text;
  VoidCallback onPressed;

  GeneralButton({this.text, this.onPressed});

  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: this.onPressed,
      padding: EdgeInsets.all(10.0),
      child: Text(
        this.text,
        style: TextStyle(fontSize: 20)
      ),
      color: secondaryBlack,
      splashColor: mainRed,
    );
  }
}
