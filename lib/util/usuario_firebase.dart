import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber/model/usuario.dart';

class UsuarioFirebase {
  static User? getUsuarioAtual() {
    FirebaseAuth auth = FirebaseAuth.instance;
    return auth.currentUser;
  }

  static Future<Usuario> getDadosUsuarioLogado() async {
    Usuario usuario = Usuario();
    User? user = getUsuarioAtual();
    if (user != null) {
      String idUsuario = user.uid;

      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentSnapshot snapshot =
          await db.collection("usuarios").doc(idUsuario).get();
      var dados = snapshot.data() as Map<String, dynamic>;

      String tipoUsuario = dados["tipoUsuario"];
      String email = dados["email"];
      String nome = dados["nome"];

      usuario.idUsuario = idUsuario;
      usuario.tipoUsuario = tipoUsuario;
      usuario.email = email;
      usuario.nome = nome;
    }
    return usuario;
  }
}
