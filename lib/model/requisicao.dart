import 'package:uber/model/usuario.dart';
import 'package:uber/model/destino.dart';

class Requisicao {
  late String id;
  late String status;
  late Usuario passageiro;
  late Usuario motorista;
  late Destino destino;

  Requisicao();

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dadosPassageiro = {
      "nome": passageiro.nome,
      "email": passageiro.email,
      "tipoUsuario": passageiro.tipoUsuario,
      "idUsuario": passageiro.idUsuario,
    };

    Map<String, dynamic> dadosDestino = {
      "rua": destino.rua,
      "numero": destino.numero,
      "bairro": destino.bairro,
      "cep": destino.cep,
      "latitude": destino.latitude,
      "longitude": destino.longitude,
    };

    Map<String, dynamic> dadosRequisicao = {
      "status": status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": dadosDestino,
    };
    return dadosRequisicao;
  }
}
