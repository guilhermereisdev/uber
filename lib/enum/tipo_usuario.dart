enum TipoUsuario {
  passageiro,
  motorista,
}

extension TipoUsuarioExtension on TipoUsuario {
  String get value {
    switch (this) {
      case TipoUsuario.passageiro:
        return "passageiro";
      case TipoUsuario.motorista:
        return "motorista";
    }
  }
}
