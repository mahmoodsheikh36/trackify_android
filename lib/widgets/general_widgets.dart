import 'package:flutter/material.dart';

import 'package:trackify_android/config.dart';
import 'package:trackify_android/widgets/music_widgets.dart';
import 'package:trackify_android/api/auth.dart';

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

class FormTextField extends StatefulWidget {
  final String hintText;
  final FormFieldValidator<String> validator;
  final bool isPassword;
  String text;

  String getText() {
    return this.text;
  }

  FormTextField(this.hintText, this.validator, {this.isPassword = false});

  @override
  State<StatefulWidget> createState() {
    return FormTextFieldState(this.hintText, this.validator, (String newValue) { text = newValue; getText(); }, isPassword: this.isPassword);
  }
}

class FormTextFieldState extends State<FormTextField> {
  final String hintText;
  final FormFieldValidator<String> validator;
  final bool isPassword;
  final ValueChanged<String> onChange;

  FormTextFieldState(this.hintText, this.validator, this.onChange, {this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: TextFormField(
        onChanged: this.onChange,
        obscureText: this.isPassword,
        validator: this.validator,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
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
    );
  }
}
