import 'package:flutter/material.dart';
import 'bluetooth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
        primaryColor: Color(0xFFFFE5B4),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: BluetoothApp(),
    );
  }
}

// Flutter will run main.dart before going to bluetooth.dart
// package:flutter/material.dart provides all the material design while creating the application
// StatelessWidget is widget when users interacts, it will not change any features
// MaterialApp is widget provides number of widgets navigator that is required to build the application
// ScaffoldWidget is under MaterialApp that provide basic function such as Application bar or background colour

// This main.dart is to run the whole program which brings us to BluetoothApp at bluetooth.dart (home screen)



