import 'package:flutter/material.dart';

import 'package:trackify_android/ui/route.dart';

class RedRoute extends MyRoute {
  RedRoute() : super(path: '/red');

  Widget buildWidget(BuildContext context) {
    return Container(
      color: Colors.red,
      child: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text('this is red', style: TextStyle(color: Colors.black)),
      ),
    );
  }
}
