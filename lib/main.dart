import 'package:flutter/material.dart';
import 'package:uber/telas/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  runApp(MaterialApp(
    title: "Uber",
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
