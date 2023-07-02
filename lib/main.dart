import 'package:flutter/material.dart';
import 'package:uber/rotas.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    title: "Uber",
    home: const Home(),
    initialRoute: "/",
    onGenerateRoute: Rotas.gerarRotas,
    theme: temaPadrao,
    debugShowCheckedModeBanner: false,
  ));
}
