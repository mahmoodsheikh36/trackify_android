import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';

class CounterWidget extends StatefulWidget {
  int count;
  Function onChange;

  CounterWidget({this.count=0, this.onChange});
  
  @override
  State<CounterWidget> createState() => CounterWidgetState();
}

class CounterWidgetState extends State<CounterWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove, size: 21, color: mainRed),
          tooltip: "decrement",
          onPressed: () {
            if (widget.count > 1) {
              setState(() {
                  widget.count -= 1;
                  widget.onChange(widget.count);
              });
            }
          },
        ),
        Text(widget.count.toString(), style: TextStyle(color: secondaryBlack, fontSize: 20)),
        IconButton(
          icon: Icon(Icons.add, size: 21, color: mainRed),
          tooltip: "increment",
          onPressed: () {
            setState(() {
                widget.count += 1;
                widget.onChange(widget.count);
            });
          },
        ),
      ]
    );
  }
}
