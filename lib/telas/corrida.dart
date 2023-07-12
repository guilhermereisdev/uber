import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber/exception/custom_null_exception.dart';
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
  Set<Marker> _marcadores = {};
  Map<String, dynamic>? _dadosRequisicao;
  String _textoBotao = "Aceitar corrida";
  Color _corBotao = Colors.black;
  Function _funcaoBotao = () {};
  String _mensagemStatus = "";
  String? _idRequisicao;
  Position? _localMotorista;
  String _statusRequisicao = StatusRequisicao.aguardando;

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
      if (position != null) {
        if (_idRequisicao != null && _idRequisicao != "") {
          if (_statusRequisicao != StatusRequisicao.aguardando) {
            UsuarioFirebase.atualizarDadosLocalizacao(
                _idRequisicao!, position.latitude, position.longitude);
          } else {
            setState(() {
              _localMotorista = position;
            });
            _statusAguardando();
          }
        } else if (_idRequisicao == null) {
          CustomNullException("_idRequisicao", "_adicionarListenerLocalizacao");
        }
      } else {
        CustomNullException("position", "_adicionarListenerLocalizacao");
      }
    });
  }

  _recuperaUltimaLocalizacaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition();
    setState(() {
      if (position != null) {
        _localMotorista = position;
      }
    });
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _exibirMarcador(Position position, String icone, String infoWindow) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      icone,
    ).then((bitmapDescriptor) {
      Marker marcador = Marker(
        markerId: MarkerId(icone),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: infoWindow),
        icon: bitmapDescriptor,
      );
      setState(() {
        _marcadores.add(marcador);
      });
    });
  }

  _recuperaRequisicao() async {
    String? idRequisicao = widget.idRequisicao;
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot =
        await db.collection("requisicoes").doc(idRequisicao).get();
  }

  _adicionarListenerRequisicao() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db
        .collection("requisicoes")
        .doc(_idRequisicao)
        .snapshots()
        .listen((event) {
      if (event.data() != null) {
        _dadosRequisicao = event.data();

        var dados = event.data() as Map<String, dynamic>;
        _statusRequisicao = dados["status"];

        switch (_statusRequisicao) {
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

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _statusAguardando() {
    _alteraBotaoPrincipal(
      "Aceitar corrida",
      Colors.black,
      () {
        _aceitarCorrida();
      },
    );

    final localMotorista = _localMotorista;
    if (localMotorista != null) {
      Position? position = Position(
        latitude: localMotorista.latitude,
        longitude: localMotorista.longitude,
        timestamp: null,
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _exibirMarcador(
        position,
        "images/motorista.png",
        "Motorista",
      );
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 19,
      );
      _movimentarCamera(cameraPosition);
    } else {
      throw CustomNullException("localMotorista", "_statusAguardando");
    }
  }

  _statusACaminho() {
    _mensagemStatus = "A caminho do passageiro";
    _alteraBotaoPrincipal("Iniciar corrida", Colors.grey, () {
      _iniciarCorrida();
    });
    double latitudePassageiro = _dadosRequisicao?["passageiro"]["latitude"];
    double longitudePassageiro = _dadosRequisicao?["passageiro"]["longitude"];
    double latitudeMotorista = _dadosRequisicao?["motorista"]["latitude"];
    double longitudeMotorista = _dadosRequisicao?["motorista"]["longitude"];
    _exibirDoisMarcadores(
      LatLng(latitudeMotorista, longitudeMotorista),
      LatLng(latitudePassageiro, longitudePassageiro),
    );

    double nLat, nLon, sLat, sLon;
    if (latitudeMotorista <= latitudePassageiro) {
      sLat = latitudeMotorista;
      nLat = latitudePassageiro;
    } else {
      sLat = latitudePassageiro;
      nLat = latitudeMotorista;
    }

    if (longitudeMotorista <= longitudePassageiro) {
      sLon = longitudeMotorista;
      nLon = longitudePassageiro;
    } else {
      sLon = longitudePassageiro;
      nLon = longitudeMotorista;
    }

    _movimentarCameraBounds(
      LatLngBounds(
        southwest: LatLng(sLat, sLon),
        northeast: LatLng(nLat, nLon),
      ),
    );
  }

  _iniciarCorrida() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection("requisicoes").doc(_idRequisicao).update({
      "origem": {
        "latitude": _dadosRequisicao?["motorista"]["latitude"],
        "longitude": _dadosRequisicao?["motorista"]["longitude"],
      },
      "status": StatusRequisicao.viagem
    });

    String idPassageiro = _dadosRequisicao?["passageiro"]["idUsuario"];
    await db
        .collection("requisicao_ativa")
        .doc(idPassageiro)
        .update({"status": StatusRequisicao.viagem});

    String idMotorista = _dadosRequisicao?["motorista"]["idUsuario"];
    await db
        .collection("requisicao_ativa_motorista")
        .doc(idMotorista)
        .update({"status": StatusRequisicao.viagem});
  }

  _exibirDoisMarcadores(LatLng latLngMotorista, LatLng latLngPassageiro) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    Set<Marker> listaMarcadores = {};

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/motorista.png",
    ).then((icone) {
      Marker marcadorMotorista = Marker(
        markerId: const MarkerId("marcador-motorista"),
        position: LatLng(latLngMotorista.latitude, latLngMotorista.longitude),
        infoWindow: const InfoWindow(title: "Local motorista"),
        icon: icone,
      );
      listaMarcadores.add(marcadorMotorista);
    });

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/passageiro.png",
    ).then((icone) {
      Marker marcadorPassageiro = Marker(
        markerId: const MarkerId("marcador-passageiro"),
        position: LatLng(latLngPassageiro.latitude, latLngPassageiro.longitude),
        infoWindow: const InfoWindow(title: "Local passageiro"),
        icon: icone,
      );
      listaMarcadores.add(marcadorPassageiro);
    });

    setState(() {
      _marcadores = listaMarcadores;
    });
  }

  _aceitarCorrida() async {
    Usuario motorista = await UsuarioFirebase.getDadosUsuarioLogado();
    motorista.latitude = _localMotorista?.latitude;
    motorista.longitude = _localMotorista?.longitude;

    FirebaseFirestore db = FirebaseFirestore.instance;
    String idRequisicao = _dadosRequisicao?["id"];
    await db.collection("requisicoes").doc(idRequisicao).update({
      "motorista": motorista.toMap(),
      "status": StatusRequisicao.aCaminho,
    }).then((_) async {
      String idPassageiro = _dadosRequisicao?["passageiro"]["idUsuario"];
      await db.collection("requisicao_ativa").doc(idPassageiro).update({
        "status": StatusRequisicao.aCaminho,
      });
      String idMotorista = motorista.idUsuario;
      await db.collection("requisicao_ativa_motorista").doc(idMotorista).set({
        "id_requisicao": idRequisicao,
        "id_usuario": idMotorista,
        "status": StatusRequisicao.aCaminho,
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _idRequisicao = widget.idRequisicao;
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerRequisicao();
    _adicionarListenerLocalizacao();
    // _recuperaRequisicao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Corrida - $_mensagemStatus"),
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
