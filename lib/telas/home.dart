import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../exception/custom_exception.dart';
import '../model/Usuario.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _controllerEmail =
      TextEditingController(text: "guilhermereis2009@hotmail.com");

  final TextEditingController _controllerSenha =
      TextEditingController(text: "11111111");
  bool _errorContainerVisibility = false;
  String _mensagemErro = "";

  bool _validarCampos() {
    if (_controllerEmail.text.isNotEmpty) {
      if (_controllerSenha.text.length >= 8) {
        return true;
      } else {
        throw CustomException("A senha deve conter no mínimo 8 caracteres.");
      }
    } else {
      throw CustomException("Preencha o campo de e-mail.");
    }
  }

  Future<bool> _logarUsuario() async {
    Usuario usuario = Usuario();
    usuario.email = _controllerEmail.text;
    usuario.senha = _controllerSenha.text;

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha,
      );
      return Future.value(true);
    } on FirebaseAuthException catch (ex) {
      switch (ex.code) {
        case "user-disabled":
          throw CustomException(
              "Esse usuário está desabilitado e não pode utilizar a plataforma.");
        case "invalid-email":
          throw CustomException("Formato de e-mail inválido.");
        case "user-not-found":
          throw CustomException("Não há usuário relacionado a esse e-mail.");
        case "wrong-password":
          throw CustomException("Senha incorreta.");
      }
    } catch (ex) {
      throw CustomException(ex.toString());
    }
    return Future.value(false);
  }

  _abreTelaCadastro() => Navigator.pushNamed(context, "/cadastro");

  _abreTelaInicialAreaLogada() =>
      Navigator.pushReplacementNamed(context, "/painel-passageiro");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/fundo.png"),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                    "images/logo.png",
                    width: 200,
                    height: 150,
                  ),
                ),
                TextField(
                  controller: _controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    hintText: "e-mail",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                TextField(
                  controller: _controllerSenha,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    hintText: "senha",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                    ),
                    onPressed: () async {
                      setState(() {
                        _mensagemErro = "";
                        _errorContainerVisibility = false;
                      });
                      try {
                        if (_validarCampos()) {
                          if (await _logarUsuario()) {
                            _abreTelaInicialAreaLogada();
                          }
                        }
                      } catch (ex) {
                        setState(() {
                          _mensagemErro = ex.toString();
                          _errorContainerVisibility = true;
                        });
                      }
                    },
                    child: const Text(
                      "Entrar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    child: const Text(
                      "Não tem conta? Cadastre-se!",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      _abreTelaCadastro();
                    },
                  ),
                ),
                Visibility(
                  visible: _errorContainerVisibility,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      color: Colors.red,
                      child: Text(
                        _mensagemErro,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
