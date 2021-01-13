import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackify_android/api.dart';
import 'package:trackify_android/widgets.dart';
import 'package:trackify_android/config.dart';

import 'package:flutter/services.dart';

void main() => runApp(TrackifyApp());

class TrackifyApp extends StatelessWidget {
  TrackifyApp() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: mainBlack, // navigation bar color
        statusBarColor: mainRed, // status bar color
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RootWidget(APIClient());
  }
}
