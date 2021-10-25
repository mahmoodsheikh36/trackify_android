import 'package:flutter/material.dart';

import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/utils.dart';

class MyRoute extends Page {
  String path;

  MyRoute({this.path}) : super(key: ValueKey(path + randomString(10))) {
    router.routes[path] = this;
  }

  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, animation2) {
        final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
        final curveTween = CurveTween(curve: Curves.easeInOut);
        return SlideTransition(
          position: animation.drive(curveTween).drive(tween),
          /* TODO: fix this, the buildWidget keeps getting called if not for the null check */
          child: router.routes[path] != null ? this.buildWidget(context) : Container(),
        );
      },
    );
  }

  Widget buildWidget(BuildContext context) { return Container(); }
}
