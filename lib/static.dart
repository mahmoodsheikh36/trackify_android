import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:trackify_android/api/api.dart';

const mainBlack = Color.fromRGBO(38, 38, 38, 1);
const secondaryBlack = Color.fromRGBO(130, 130, 130, 1);
const tertiaryBlack = Color.fromRGBO(17, 17, 17, 0.65);
const textColor = Colors.white;
const mainRed = Color.fromRGBO(210, 93, 93, 1);
const textStyle = TextStyle(
  color: textColor,
);
const highlightedTextStyle = TextStyle(
  color: mainRed,
  fontSize: 17
);

const String BACKEND = kDebugMode ? 'http://localhost:5000' : 'https://trackifyapp.net';

final APIClient apiClient = APIClient();
