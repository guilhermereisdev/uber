import 'package:flutter/material.dart';

class PainelMotorista extends StatefulWidget {
  const PainelMotorista({super.key});

  @override
  State<PainelMotorista> createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Motorista"),
      ),
      body: Container(),
    );
  }
}
