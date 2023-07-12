import 'package:google_maps_flutter/google_maps_flutter.dart';

class Marcador {
  late LatLng local;
  late String caminhoImagem;
  late String titulo;

  Marcador(this.local, this.caminhoImagem, this.titulo);
}
