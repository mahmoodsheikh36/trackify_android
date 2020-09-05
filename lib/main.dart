import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackify_android/api.dart';
import 'package:trackify_android/widgets.dart';

void main() => runApp(TrackifyApp());

class TrackifyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RootWidget(APIClient());
  }
}