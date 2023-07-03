import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber/exception/custom_exception.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({super.key});

  @override
  State<PainelPassageiro> createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(-23.563999, -46.653256),
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializarTelaAposChecarPermissoes();
  }

  Future<void> _inicializarTelaAposChecarPermissoes() async {
    bool permissaoConcedida = await _checaPermissoesDeLocalizacao();

    if (permissaoConcedida) {
      _recuperaUltimaLocalizacaoConhecida();
      _adicionarListenerLocalizacao();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _deslogarUsuario() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.signOut();
      return Future.value(true);
    } catch (ex) {
      throw CustomException(ex.toString());
    }
  }

  _abreTelaLogin() => Navigator.pushReplacementNamed(context, "/");

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<bool> _checaPermissoesDeLocalizacao() async {
    bool isServiceEnabled;
    LocationPermission permission;

    isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return Future.error('Os serviços de localização estão desativados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('As permissões de localização foram negadas');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      //TODO: Criar tela que resolve o processo de explicar para o usuário que ele precisa ir nas configs liberar a permissão caso deseje usar o app;
      return Future.error(
          'As permissões de localização estão permanentemente negadas.');
    }

    return true;
  }

  _recuperaUltimaLocalizacaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition();
    setState(() {
      if (position != null) {
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

  _adicionarListenerLocalizacao() {
    var locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((position) {
      _cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 19,
      );
      _movimentarCamera(_cameraPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Passageiro"),
        actions: [
          PopupMenuButton(
            onSelected: (item) async {
              switch (item) {
                case "/":
                  if (await _deslogarUsuario()) {
                    _abreTelaLogin();
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              const PopupMenuItem(
                value: "a",
                child: Text('Configurações'),
              ),
              const PopupMenuItem(
                value: "/",
                child: Text('Deslogar'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Text("Validando permissões"),
                ],
              ),
            )
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _cameraPosition,
              onMapCreated: _onMapCreated,
              myLocationEnabled: true,
            ),
    );
  }
}
