import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber/model/usuario.dart';
import 'package:uber/util/usuario_firebase.dart';

import '../enum/status_requisicao.dart';

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
  Map<String, dynamic>? _dadosRequisicao;
  Position? _localMotorista;
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
      setState(() {
        _localMotorista = position;
      });
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
        _localMotorista = position;
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

  _recuperaRequisicao() async {
    String? idRequisicao = widget.idRequisicao;
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot =
        await db.collection("requisicoes").doc(idRequisicao).get();
    _dadosRequisicao = snapshot.data() as Map<String, dynamic>?;
    _adicionarListenerRequisicao();
  }

  _adicionarListenerRequisicao() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    String idRequisicao = _dadosRequisicao?["id"];
    db.collection("requisicoes").doc(idRequisicao).snapshots().listen((event) {
      if (event.data() != null) {
        var dados = event.data() as Map<String, dynamic>;
        String status = dados["status"];

        switch (status) {
          case StatusRequisicao.aguardando:
            _statusAguardando();
            break;
          case StatusRequisicao.aCaminho:
            _statusACaminho();
            break;
          case StatusRequisicao.finalizada:
            break;
          case StatusRequisicao.viagem:
            break;
        }
      }
    });
  }

  _statusAguardando() {
    _alteraBotaoPrincipal(
      "Aceitar corrida",
      Colors.black,
      () {
        _aceitarCorrida();
      },
    );
  }

  _statusACaminho() {
    _alteraBotaoPrincipal("A caminho do passageiro", Colors.grey, () {});
  }

  _aceitarCorrida() async {
    Usuario motorista = await UsuarioFirebase.getDadosUsuarioLogado();
    motorista.latitude = _localMotorista?.latitude;
    motorista.longitude = _localMotorista?.longitude;

    FirebaseFirestore db = FirebaseFirestore.instance;
    String idRequisicao = _dadosRequisicao?["id"];
    db.collection("requisicoes").doc(idRequisicao).update({
      "motorista": motorista.toMap(),
      "status": StatusRequisicao.aCaminho,
    }).then((_) {
      String idPassageiro = _dadosRequisicao?["passageiro"]["idUsuario"];
      db.collection("requisicao_ativa").doc(idPassageiro).update({
        "status": StatusRequisicao.aCaminho,
      });
      String idMotorista = motorista.idUsuario;
      db.collection("requisicao_ativa_motorista").doc(idMotorista).set({
        "id_requisicao": idRequisicao,
        "id_usuario": idMotorista,
        "status": StatusRequisicao.aCaminho,
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
    _recuperaRequisicao();
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
