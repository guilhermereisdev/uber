import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/exception/custom_exception.dart';
import 'package:uber/model/usuario.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final TextEditingController _controllerNome = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerSenha = TextEditingController();
  bool _tipoUsuario = false;
  bool _errorContainerVisibility = false;
  String _mensagemErro = "";

  bool _validarCampos() {
    if (_controllerNome.text.isNotEmpty) {
      if (_controllerNome.text.contains(" ")) {
        if (_controllerEmail.text.isNotEmpty) {
          if (_controllerSenha.text.length >= 8) {
            return true;
          } else {
            throw CustomException(
                "A senha deve conter no mínimo 8 caracteres.");
          }
        } else {
          throw CustomException("Preencha o campo de e-mail.");
        }
      } else {
        throw CustomException("Prencha seu nome completo.");
      }
    } else {
      throw CustomException("Preencha o campo de nome.");
    }
  }

  Future<bool> _cadastrarUsuario() async {
    Usuario usuario = Usuario();
    usuario.nome = _controllerNome.text;
    usuario.email = _controllerEmail.text;
    usuario.senha = _controllerSenha.text;
    usuario.tipoUsuario = usuario.verificaTipoUsuario(_tipoUsuario);

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore db = FirebaseFirestore.instance;
      await auth
          .createUserWithEmailAndPassword(
              email: usuario.email, password: usuario.senha)
          .then((firebaseUser) => {
                db
                    .collection("usuarios")
                    .doc(firebaseUser.user?.uid)
                    .set(usuario.toMap())
              });
      return Future.value(true);
    } on FirebaseAuthException catch (ex) {
      switch (ex.code) {
        case "email-already-in-use":
          throw CustomException(
              "Esse e-mail já está cadastrado. Tente entrar normalmente ou use a ferramenta de recuperar senha.");
        case "invalid-email":
          throw CustomException("Formato de e-mail inválido.");
        case "weak-password":
          throw CustomException("Use uma senha mais forte.");
      }
    } catch (ex) {
      throw CustomException(ex.toString());
    }
    return Future.value(false);
  }

  _abrirTelaInicial() {
    _tipoUsuario
        ? Navigator.pushNamedAndRemoveUntil(
            context,
            "/painel-motorista",
            (_) => false,
          )
        : Navigator.pushNamedAndRemoveUntil(
            context,
            "/painel-passageiro",
            (_) => false,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro"),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controllerNome,
                  keyboardType: TextInputType.name,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      hintText: "nome completo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      )),
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
                      )),
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
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text("Tipo de usuário:")],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Passageiro"),
                          Switch(
                            value: _tipoUsuario,
                            onChanged: (valor) {
                              setState(() {
                                _tipoUsuario = valor;
                              });
                            },
                          ),
                          const Text("Motorista"),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
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
                          if (await _cadastrarUsuario()) {
                            _abrirTelaInicial();
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
                      "Cadastrar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
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
