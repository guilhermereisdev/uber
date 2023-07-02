import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/exception/custom_exception.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({super.key});

  @override
  State<PainelPassageiro> createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  Future<bool> _deslogarUsuario() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.signOut();
      return Future.value(true);
    } catch (ex) {
      throw CustomException(ex.toString());
    }
  }

  _abreTelaLogin() => Navigator.pushReplacementNamed(context, "/");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Passageiro"),
        actions: [
          PopupMenuButton(
            // Callback that sets the selected popup menu item.
            onSelected: (item) async {
              switch (item) {
                case "/":
                  if (await _deslogarUsuario()) {
                    _abreTelaLogin();
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              const PopupMenuItem(
                value: "a",
                child: Text('Configurações'),
              ),
              const PopupMenuItem(
                value: "/",
                child: Text('Deslogar'),
              ),
            ],
          ),
        ],
      ),
      body: Container(),
    );
  }
}
