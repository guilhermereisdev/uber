enum StatusRequisicao {
  aguardando,
  a_caminho,
  viagem,
  finalizada,
}

extension StatusRequisicaoExtension on StatusRequisicao {
  String get value {
    switch (this) {
      case StatusRequisicao.aguardando:
        return "aguardando";
      case StatusRequisicao.a_caminho:
        return "a_caminho";
      case StatusRequisicao.viagem:
        return "viagem";
      case StatusRequisicao.finalizada:
        return "finalizada";
    }
  }
}
