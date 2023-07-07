import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/enum/status_requisicao.dart';
import 'package:uber/util/usuario_firebase.dart';

import '../exception/custom_exception.dart';

class PainelMotorista extends StatefulWidget {
  const PainelMotorista({super.key});

  @override
  State<PainelMotorista> createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  final _controller = StreamController<QuerySnapshot>.broadcast();

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

  _adicionarListenerRequisicoes() {
    final stream = db
        .collection("requisicoes")
        .where("status", isEqualTo: StatusRequisicao.aguardando)
        .snapshots();
    stream.listen((event) {
      _controller.add(event);
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperaRequisicaoAtivaMotorista();
  }

  _recuperaRequisicaoAtivaMotorista() async {
    User? user = await UsuarioFirebase.getUsuarioAtual();
    DocumentSnapshot snapshot =
        await db.collection("requisicao_ativa_motorista").doc(user?.uid).get();
    var dadosRequisicao = snapshot.data() as Map<String, dynamic>?;

    if (dadosRequisicao == null) {
      _adicionarListenerRequisicoes();
    } else {
      String idRequisicao = dadosRequisicao["id_requisicao"];
      await Future.microtask(() {
        Navigator.pushReplacementNamed(
          context,
          "/corrida",
          arguments: idRequisicao,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var mensagemCarregando = const Center(
      child: Column(
        children: [
          Text("Carregando requisições"),
          CircularProgressIndicator(),
        ],
      ),
    );

    var mensagemNaoTemDados = const Center(
      child: Text(
        "Você tem nenhuma requisição",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Motorista"),
        actions: [
          PopupMenuButton(
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return mensagemCarregando;
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Text("Erro ao carregar os dados");
              } else {
                QuerySnapshot? querySnapshot = snapshot.data;
                if (querySnapshot != null && querySnapshot.docs.isEmpty) {
                  return mensagemNaoTemDados;
                } else if (querySnapshot != null) {
                  return ListView.separated(
                    separatorBuilder: (context, index) => const Divider(
                      height: 2,
                      color: Colors.grey,
                    ),
                    itemCount: querySnapshot.docs.length,
                    itemBuilder: (context, index) {
                      List<DocumentSnapshot> requisicoes =
                          querySnapshot.docs.toList();
                      DocumentSnapshot item = requisicoes[index];

                      String idRequisicao = item["id"];
                      String nomePassageiro = item["passageiro"]["nome"];
                      String rua = item["destino"]["rua"];
                      String numero = item["destino"]["numero"];

                      return ListTile(
                        title: Text(nomePassageiro),
                        subtitle: Text("Destino: $rua, $numero"),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/corrida",
                            arguments: idRequisicao,
                          );
                        },
                      );
                    },
                  );
                }
              }
              return const Text("Erro ao construir a lista de viagens");
          }
        },
      ),
    );
  }
}
