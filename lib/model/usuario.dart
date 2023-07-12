import 'package:uber/enum/tipo_usuario.dart';

class Usuario {
  late String idUsuario;
  late String nome;
  late String email;
  late String senha;
  late String tipoUsuario;
  double? latitude;
  double? longitude;

  Usuario();

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "idUsuario": idUsuario,
      "nome": nome,
      "email": email,
      "tipoUsuario": tipoUsuario,
      "latitude": latitude,
      "longitude": longitude,
    };
    return map;
  }

  String verificaTipoUsuario(bool tipoUsuario) =>
      tipoUsuario ? TipoUsuario.motorista : TipoUsuario.passageiro;
}
