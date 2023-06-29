import 'package:flutter/material.dart';
import 'package:uber/telas/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final ThemeData temaPadrao = ThemeData(
  appBarTheme: const AppBarTheme(color: Colors.black),
  inputDecorationTheme: const InputDecorationTheme(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 1, color: Colors.black),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 4, color: Colors.black),
    ),
  ),
);

void main() async {
  runApp(MaterialApp(
    title: "Uber",
    home: const Home(),
    theme: temaPadrao,
    debugShowCheckedModeBanner: false,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
