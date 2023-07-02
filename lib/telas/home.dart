import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _loadingVisibility = false;
  bool _passwordVisibility = true;

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

  Future<String?> _logarUsuario() async {
    Usuario usuario = Usuario();
    usuario.email = _controllerEmail.text;
    usuario.senha = _controllerSenha.text;

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      final usuarioLogado = await auth.signInWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha,
      );

      if (usuarioLogado.user?.uid != null) {
        return usuarioLogado.user?.uid;
      } else {
        throw CustomException("Usuário nulo.");
      }
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
        case "too-many-requests":
          throw CustomException(
              "Muitas tentativas incorretas de login.\nO acesso a essa conta foi temporariamente suspenso.\n\nVocê pode acessar sua conta imediatamente ao alterar sua senha na opção \"Esqueci a senha\" ou tentar novamente mais tarde.");
      }
    } catch (ex) {
      throw CustomException(ex.toString());
    }
    throw CustomException("Função de logar usuário não foi executada.");
  }

  _abreTelaCadastro() => Navigator.pushNamed(context, "/cadastro");

  _abreTelaInicialAreaLogadaPassageiro() =>
      Navigator.pushReplacementNamed(context, "/painel-passageiro");

  _abreTelaInicialAreaLogadaMotorista() =>
      Navigator.pushReplacementNamed(context, "/painel-motorista");

  _redirecionaParaTelaInicialLogadaPorTipoUsuario(String? idUsuario) async {
    var db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot =
        await db.collection("usuarios").doc(idUsuario).get();
    var dados = snapshot.data() as Map<String, dynamic>;
    String tipoUsuario = dados["tipoUsuario"];
    switch (tipoUsuario) {
      case "motorista":
        _abreTelaInicialAreaLogadaMotorista();
        break;
      case "passageiro":
        _abreTelaInicialAreaLogadaPassageiro();
        break;
    }
  }

  _exibirLoading(bool exibir) {
    setState(() {
      _loadingVisibility = exibir ? true : false;
    });
  }

  _exibirMensagemErro(bool exibir, {String mensagem = ""}) {
    setState(() {
      _mensagemErro = mensagem;
      _errorContainerVisibility = exibir ? true : false;
    });
  }

  String? _verificaUsuarioLogado() {
    var auth = FirebaseAuth.instance;
    var usuarioLogado = auth.currentUser;
    return usuarioLogado?.uid;
  }

  @override
  Widget build(BuildContext context) {
    String? idUsuario = _verificaUsuarioLogado();
    if (idUsuario != null) {
      _redirecionaParaTelaInicialLogadaPorTipoUsuario(idUsuario);
      return const Scaffold();
    } else {
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
                    obscureText: _passwordVisibility,
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
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisibility
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(
                            () {
                              _passwordVisibility = !_passwordVisibility;
                            },
                          );
                        },
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
                        _exibirLoading(true);
                        _exibirMensagemErro(false);
                        try {
                          if (_validarCampos()) {
                            await _redirecionaParaTelaInicialLogadaPorTipoUsuario(
                                await _logarUsuario());
                          }
                        } catch (ex) {
                          _exibirLoading(false);
                          _exibirMensagemErro(true, mensagem: ex.toString());
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
                    visible: _loadingVisibility,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
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
}
