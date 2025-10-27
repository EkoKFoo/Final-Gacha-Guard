import 'package:flutter/material.dart';

class NavigationHelper{
  // push to new page

  static void push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  //replace current screen
  static void pushReplacement(BuildContext context, Widget screen) {
    Navigator.pushReplacement(context, 
    MaterialPageRoute(builder: (context) => screen));
  }

  static void pop(BuildContext context) {
  Navigator.pop(context);
  }
}