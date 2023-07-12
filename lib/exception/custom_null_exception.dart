class CustomNullException implements Exception {
  final String functionName;
  final String variableName;

  CustomNullException(this.variableName, this.functionName);

  @override
  String toString() {
    return "Erro: A variável $variableName está nula na função $functionName.";
  }
}
