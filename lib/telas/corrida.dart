import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Corrida extends StatefulWidget {
  final String? idRequisicao;

  const Corrida({super.key, this.idRequisicao});

  @override
  State<Corrida> createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(-23.563999, -46.653256),
  );
  final Set<Marker> _marcadores = {};
  String _textoBotao = "Aceitar corrida";
  Color _corBotao = Colors.black;
  Function _funcaoBotao = () {};

  _alteraBotaoPrincipal(String texto, Color cor, Function funcao) {
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _adicionarListenerLocalizacao() {
    var locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((position) {
      _exibirMarcadorPassageiro(position);
      _cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 19,
      );
      _movimentarCamera(_cameraPosition);
    });
  }

  _recuperaUltimaLocalizacaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition();
    setState(() {
      if (position != null) {
        _exibirMarcadorPassageiro(position);
        _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 19,
        );
        _movimentarCamera(_cameraPosition);
      }
    });
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _exibirMarcadorPassageiro(Position position) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/motorista.png",
    ).then((icone) {
      Marker marcadorPassageiro = Marker(
        markerId: const MarkerId("marcador-motorista"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: "Meu local"),
        icon: icone,
      );
      setState(() {
        _marcadores.add(marcadorPassageiro);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Corrida"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _cameraPosition,
            onMapCreated: _onMapCreated,
            // myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _marcadores,
            zoomControlsEnabled: false,
          ),
          Positioned(
            right: 0,
            left: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _corBotao,
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                ),
                onPressed: () => _funcaoBotao(),
                child: Text(
                  _textoBotao,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
