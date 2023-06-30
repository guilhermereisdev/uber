import 'package:uber/enum/tipo_usuario.dart';

class Usuario {
  late String idUsuario;
  late String nome;
  late String email;
  late String senha;
  late String tipoUsuario;

  Usuario();

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "nome": nome,
      "email": email,
      "tipoUsuario": tipoUsuario,
    };
    return map;
  }

  String verificaTipoUsuario(bool tipoUsuario) =>
      tipoUsuario ? TipoUsuario.motorista.value : TipoUsuario.passageiro.value;
}
