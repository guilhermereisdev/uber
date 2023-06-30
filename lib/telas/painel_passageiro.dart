import 'package:flutter/material.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({super.key});

  @override
  State<PainelPassageiro> createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Passageiro"),
      ),
      body: Container(),
    );
  }
}
