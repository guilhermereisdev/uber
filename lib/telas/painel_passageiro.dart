import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber/enum/routes_names.dart';
import 'package:uber/enum/status_requisicao.dart';
import 'package:uber/exception/custom_exception.dart';
import 'package:uber/exception/custom_null_exception.dart';
import 'package:uber/model/destino.dart';
import 'package:uber/model/marcador.dart';
import 'package:uber/model/requisicao.dart';
import 'package:uber/model/usuario.dart';
import 'package:uber/util/usuario_firebase.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({super.key});

  @override
  State<PainelPassageiro> createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  final Completer<GoogleMapController> _controller = Completer();
  final CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(-23.563999, -46.653256),
  );
  bool _isLoading = true;
  Set<Marker> _marcadores = {};
  final TextEditingController _controllerDestino =
      TextEditingController(text: "Av Paulista, 807");
  bool _exibirCaixaEnderecoDestino = true;
  String _textoBotao = "Chamar Uber";
  Color _corBotao = Colors.black;
  Function _funcaoBotao = () {};
  String? _idRequisicao;
  Position? _localPassageiro;
  Map<String, dynamic>? _dadosRequisicao;
  StreamSubscription<DocumentSnapshot>? _streamSubscriptionRequisicoes;

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

  _abreTelaLogin() => Navigator.pushReplacementNamed(context, RoutesNames.home);

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
      //TODO: Criar tela que resolva o processo de explicar para o usuário que ele precisa ir nas configs liberar a permissão caso deseje usar o app;
      return Future.error(
          'As permissões de localização estão permanentemente negadas.');
    }

    return true;
  }

  _recuperaUltimaLocalizacaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition();
    setState(() {
      if (position != null) {
        _localPassageiro = position;
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
      if (_idRequisicao != null && _idRequisicao != "") {
        UsuarioFirebase.atualizarDadosLocalizacao(
          _idRequisicao!,
          position.latitude,
          position.longitude,
          "passageiro",
        );
      } else {
        setState(() {
          _localPassageiro = position;
        });
        _statusUberNaoChamado();
      }

      // _exibirMarcadorPassageiro(position);
      // _cameraPosition = CameraPosition(
      //     target: LatLng(position.latitude, position.longitude), zoom: 19);
      // _localPassageiro = position;
      // _movimentarCamera(_cameraPosition);
    });
  }

  _exibirMarcadorPassageiro(Position position) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/passageiro.png",
    ).then((icone) {
      Marker marcadorPassageiro = Marker(
        markerId: const MarkerId("marcador-passageiro"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: "Meu local"),
        icon: icone,
      );
      setState(() {
        _marcadores.add(marcadorPassageiro);
      });
    });
  }

  _chamarUber() async {
    String enderecoDestino = _controllerDestino.text;
    try {
      if (enderecoDestino.trim().isNotEmpty) {
        List<Location> listaLocation = await locationFromAddress(
          enderecoDestino,
          localeIdentifier: "pt_BR",
        );
        if (listaLocation.isNotEmpty) {
          List<Placemark> listaPlacemark = await placemarkFromCoordinates(
            listaLocation[0].latitude,
            listaLocation[0].longitude,
            localeIdentifier: "pt_BR",
          );
          if (listaPlacemark.isNotEmpty) {
            Placemark enderecoCompleto = listaPlacemark[0];
            Destino destino = Destino();
            destino.cidade = enderecoCompleto.subAdministrativeArea.toString();
            destino.cep = enderecoCompleto.postalCode.toString();
            destino.bairro = enderecoCompleto.subLocality.toString();
            destino.rua = enderecoCompleto.thoroughfare.toString();
            destino.numero = enderecoCompleto.subThoroughfare.toString();
            destino.estado = enderecoCompleto.administrativeArea.toString();
            destino.latitude = listaLocation[0].latitude;
            destino.longitude = listaLocation[0].longitude;

            if (await _confirmarEndereco(destino) == true) {
              _salvarRequisicao(destino);
            }
          }
        }
      } else {
        _exibeAlertSimplesDeErro(
          titulo: "Erro: Destino em branco",
          "Digite um endereço no campo de destino.",
        );
      }
    } on PlatformException {
      _exibeAlertSimplesDeErro(
          "Muitas requisições estão sendo feitas. Tente novamente.");
    } on NoResultFoundException {
      _exibeAlertSimplesDeErro(
        titulo: "Nenhum resultado encontrado.",
        "Tente digitar dados como nome de rua, número e cidade.",
      );
    }
  }

  _cancelarUber() async {
    User? user = await UsuarioFirebase.getUsuarioAtual();
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db
        .collection("requisicoes")
        .doc(_idRequisicao)
        .update({"status": StatusRequisicao.cancelada}).then((_) async {
      await db.collection("requisicao_ativa").doc(user?.uid).delete();
    });
  }

  _exibeAlertSimplesDeErro(String mensagem, {String titulo = ""}) {
    Widget? titleText = titulo.isEmpty ? null : Text(titulo);
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: titleText,
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Entendi",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  _salvarRequisicao(Destino destino) async {
    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    passageiro.latitude = _localPassageiro?.latitude;
    passageiro.longitude = _localPassageiro?.longitude;

    Requisicao requisicao = Requisicao();
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.aguardando;

    // Salvar requisição
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db
        .collection("requisicoes")
        .doc(requisicao.id)
        .set(requisicao.toMap());

    // Salvar requisição ativa
    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva["id_requisicao"] = requisicao.id;
    dadosRequisicaoAtiva["id_usuario"] = passageiro.idUsuario;
    dadosRequisicaoAtiva["status"] = StatusRequisicao.aguardando;

    await db
        .collection("requisicao_ativa")
        .doc(passageiro.idUsuario)
        .set(dadosRequisicaoAtiva);

    if (_streamSubscriptionRequisicoes == null) {
      _adicionarListenerRequisicao(requisicao.id);
    }
  }

  Future<bool> _confirmarEndereco(Destino destino) async {
    bool isConfirmed = false;
    String enderecoConfirmacao;
    enderecoConfirmacao = "${destino.rua}, ${destino.numero}"
        "\nBairro ${destino.bairro}"
        "\n${destino.cidade} - ${destino.estado}"
        "\n\n\nCaso o endereço não esteja correto, vá em \"Cancelar\" e insira mais detalhes, como número ou cidade.";

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmação do endereço"),
          content: Text(enderecoConfirmacao),
          // contentPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                isConfirmed = false;
              },
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                isConfirmed = true;
                Navigator.pop(context);
              },
              child: const Text(
                "Está correto",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
    return isConfirmed;
  }

  _alteraBotaoPrincipal(String texto, Color cor, Function funcao) {
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _statusUberNaoChamado() {
    _exibirCaixaEnderecoDestino = true;
    _alteraBotaoPrincipal(
      "Chamar Uber",
      Colors.black,
      () {
        _chamarUber();
      },
    );

    final localPassageiro = _localPassageiro;
    if (localPassageiro != null) {
      Position position = Position(
          longitude: localPassageiro.longitude,
          latitude: localPassageiro.latitude,
          timestamp: null,
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0);
      _exibirMarcadorPassageiro(position);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 19,
      );

      _movimentarCamera(cameraPosition);
    } else {
      CustomNullException("localPassageiro", "_statusUberNaoChamado");
    }
  }

  _statusAguardando() {
    _exibirCaixaEnderecoDestino = false;
    _alteraBotaoPrincipal(
      "Cancelar",
      Colors.red,
      () {
        _cancelarUber();
      },
    );

    double passageiroLat = _dadosRequisicao?["passageiro"]["latitude"];
    double passageiroLon = _dadosRequisicao?["passageiro"]["longitude"];
    Position position = Position(
        longitude: passageiroLon,
        latitude: passageiroLat,
        timestamp: null,
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0);
    _exibirMarcadorPassageiro(position);
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 19,
    );

    _movimentarCamera(cameraPosition);
  }

  _statusACaminho() {
    _exibirCaixaEnderecoDestino = false;
    _alteraBotaoPrincipal(
      "Motorista a caminho",
      Colors.grey,
      () {},
    );

    double latitudeDestino = _dadosRequisicao?["passageiro"]["latitude"];
    double longitudeDestino = _dadosRequisicao?["passageiro"]["longitude"];
    double latitudeOrigem = _dadosRequisicao?["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao?["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
      LatLng(latitudeOrigem, longitudeOrigem),
      "images/motorista.png",
      "Local motorista",
    );

    Marcador marcadorDestino = Marcador(
      LatLng(latitudeDestino, longitudeDestino),
      "images/passageiro.png",
      "Local destino",
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _statusEmViagem() {
    _exibirCaixaEnderecoDestino = false;
    _alteraBotaoPrincipal("Em viagem", Colors.grey, () {});

    double latitudeDestino = _dadosRequisicao?["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao?["destino"]["longitude"];
    double latitudeOrigem = _dadosRequisicao?["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao?["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
      LatLng(latitudeOrigem, longitudeOrigem),
      "images/motorista.png",
      "Local motorista",
    );

    Marcador marcadorDestino = Marcador(
      LatLng(latitudeDestino, longitudeDestino),
      "images/destino.png",
      "Local destino",
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _exibirCentralizarDoisMarcadores(
      Marcador marcadorOrigem, Marcador marcadorDestino) {
    double latitudeOrigem = marcadorOrigem.local.latitude;
    double longitudeOrigem = marcadorOrigem.local.longitude;
    double latitudeDestino = marcadorDestino.local.latitude;
    double longitudeDestino = marcadorDestino.local.longitude;

    _exibirDoisMarcadores(marcadorOrigem, marcadorDestino);

    double nLat, nLon, sLat, sLon;
    if (latitudeOrigem <= latitudeDestino) {
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    } else {
      sLat = latitudeDestino;
      nLat = latitudeOrigem;
    }

    if (longitudeOrigem <= longitudeDestino) {
      sLon = longitudeOrigem;
      nLon = longitudeDestino;
    } else {
      sLon = longitudeDestino;
      nLon = longitudeOrigem;
    }

    _movimentarCameraBounds(
      LatLngBounds(
        southwest: LatLng(sLat, sLon),
        northeast: LatLng(nLat, nLon),
      ),
    );
  }

  _exibirDoisMarcadores(Marcador marcadorOrigem, Marcador marcadorDestino) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    LatLng latLngOrigem = marcadorOrigem.local;
    LatLng latLngDestino = marcadorDestino.local;
    Set<Marker> listaMarcadores = {};

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      marcadorOrigem.caminhoImagem,
    ).then((icone) {
      Marker mOrigem = Marker(
        markerId: MarkerId(marcadorOrigem.caminhoImagem),
        position: LatLng(latLngOrigem.latitude, latLngOrigem.longitude),
        infoWindow: InfoWindow(title: marcadorOrigem.titulo),
        icon: icone,
      );
      listaMarcadores.add(mOrigem);
    });

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      marcadorDestino.caminhoImagem,
    ).then((icone) {
      Marker mDestino = Marker(
        markerId: MarkerId(marcadorDestino.caminhoImagem),
        position: LatLng(latLngDestino.latitude, latLngDestino.longitude),
        infoWindow: InfoWindow(title: marcadorDestino.titulo),
        icon: icone,
      );
      listaMarcadores.add(mDestino);
    });

    setState(() {
      _marcadores = listaMarcadores;
    });
  }

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _recuperarRequisicaoAtiva() async {
    User? user = await UsuarioFirebase.getUsuarioAtual();
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot documentSnapshot =
        await db.collection("requisicao_ativa").doc(user?.uid).get();
    var dadosRequisicao = documentSnapshot.data() as Map<String, dynamic>?;

    if (dadosRequisicao != null) {
      _idRequisicao = dadosRequisicao["id_requisicao"];
      if (_idRequisicao != null) {
        _adicionarListenerRequisicao(_idRequisicao!);
      }
    } else {
      _statusUberNaoChamado();
    }
  }

  _adicionarListenerRequisicao(String idRequisicao) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    _streamSubscriptionRequisicoes = db
        .collection("requisicoes")
        .doc(idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        var dados = snapshot.data() as Map<String, dynamic>;
        _dadosRequisicao = dados;
        String status = dados["status"];
        _idRequisicao = dados["id"];

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
            _statusEmViagem();
            break;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperarRequisicaoAtiva();
    _inicializarTelaAposChecarPermissoes();
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
          : Stack(
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
                Visibility(
                  visible: _exibirCaixaEnderecoDestino,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white,
                            ),
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                icon: Container(
                                  margin: const EdgeInsets.only(left: 16),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                  ),
                                ),
                                hintText: "Meu local",
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.only(left: 0, top: 0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 55,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white,
                            ),
                            child: TextField(
                              controller: _controllerDestino,
                              decoration: InputDecoration(
                                  icon: Container(
                                    margin: const EdgeInsets.only(left: 16),
                                    child: const Icon(
                                      Icons.local_taxi,
                                      color: Colors.black,
                                    ),
                                  ),
                                  hintText: "Digite o destino",
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.only(left: 0, top: 0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

  @override
  void dispose() {
    super.dispose();
    _streamSubscriptionRequisicoes?.cancel();
  }
}
