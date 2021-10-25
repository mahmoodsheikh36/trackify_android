import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';

class GenericRouteFiller extends StatelessWidget {
  Widget child;
  Widget title;
  Widget controls;

  GenericRouteFiller({this.title, this.controls, this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          backgroundColor: mainBlack,
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: mainRed,
                  borderRadius: BorderRadius.only(
                    bottomLeft: const Radius.circular(30.0),
                    bottomRight: const Radius.circular(30.0),
                  )
                ),
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: mainBlack),
                        tooltip: "close",
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      width: 30,
                    ),
                    this.title,
                    this.controls != null ? this.controls : Container(width: 30),
                  ],
                ),
              ),
              Container(height: 5),
              Expanded(child: this.child),
            ],
          ),
        )
      )
    );
  }
}
