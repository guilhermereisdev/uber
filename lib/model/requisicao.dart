import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/model/destino.dart';
import 'package:uber/model/usuario.dart';

class Requisicao {
  late String id;
  late String status;
  late Usuario passageiro;
  late Usuario motorista;
  late Destino destino;

  Requisicao() {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference ref = db.collection("requisicoes").doc();
    id = ref.id;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dadosPassageiro = {
      "nome": passageiro.nome,
      "email": passageiro.email,
      "tipoUsuario": passageiro.tipoUsuario,
      "idUsuario": passageiro.idUsuario,
      "latitude": passageiro.latitude,
      "longitude": passageiro.longitude,
    };

    Map<String, dynamic> dadosDestino = {
      "rua": destino.rua,
      "numero": destino.numero,
      "bairro": destino.bairro,
      "cep": destino.cep,
      "cidade": destino.cidade,
      "estado": destino.estado,
      "latitude": destino.latitude,
      "longitude": destino.longitude,
    };

    Map<String, dynamic> dadosRequisicao = {
      "id": id,
      "status": status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": dadosDestino,
    };
    return dadosRequisicao;
  }
}
