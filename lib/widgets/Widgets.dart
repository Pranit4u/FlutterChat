import 'package:flutter/material.dart';

AppBar appBarMain(){
  return AppBar(
    title: Image.asset("assets/images/appBar.png", height: 50.0,),
  );
}

TextStyle simpleTextStyle() {
  return TextStyle(color: Colors.white, fontSize: 16);
}
TextStyle biggerTextStyle() {
  return TextStyle(color: Colors.white, fontSize: 17);
}
InputDecoration textFieldInputDecoration(String hint){
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: Colors.white54,
    ),
    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
  );
}