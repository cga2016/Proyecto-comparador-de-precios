// ignore_for_file: unnecessary_type_check

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proyectocomparador/models/usuario.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  final String collectionName = 'user';
  final String contadorDocPath = 'contadores/usuarios';
  final String listaCollection = 'lista';
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> addUsuario(Usuario usuario) async {
    await _firestore.collection(collectionName).add(usuario.toJson());
  }

  Future<int> obtenerSiguienteId() async {
    final DocumentReference contadorRef = _firestore.doc(contadorDocPath);

    return _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(contadorRef);

      if (!snapshot.exists) {
        transaction.set(contadorRef, {'ultimoId': 1});
        return 1;
      } else {
        final data = snapshot.data() as Map<String, dynamic>? ?? {};
        final ultimo = data['ultimoId'];
        int ultimoInt;
        if (ultimo is int) {
          ultimoInt = ultimo;
        } else {
          ultimoInt = int.tryParse(ultimo?.toString() ?? '') ?? 0;
        }
        final siguiente = ultimoInt + 1;
        transaction.update(contadorRef, {'ultimoId': siguiente});
        return siguiente;
      }
    });
  }

  Future<Map<String, dynamic>?> buscarUsuario(
      String correo, String contrasena) async {
    var snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .where('contrasena', isEqualTo: contrasena)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      snapshot = await _firestore
          .collection(collectionName)
          .where('nick', isEqualTo: correo)
          .where('contrasena', isEqualTo: contrasena)
          .limit(1)
          .get();
    }

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final dataRaw = doc.data();

      final data = (dataRaw is Map<String, dynamic>)
          ? dataRaw
          : Map<String, dynamic>.from(dataRaw as Map);
      final usuario = Usuario.fromJson(data);

      UsuarioIniciado.iniciarSesion(usuario);

      return {
        'usuario': usuario,
        'docId': doc.id,
      };
    } else {
      return null;
    }
  }

  /*Future<bool> correoExiste(String correo) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }*/

  // user.listaFavoritos
  Future<void> addFavoritoPorDocId(String docId, String favorito) async {
    await _firestore.collection(collectionName).doc(docId).update({
      'listaFavoritos': FieldValue.arrayUnion([favorito])
    });
  }

  Future<void> addFavoritoPorCorreo(String correo, String favorito) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      final snap2 = await _firestore
          .collection(collectionName)
          .where('nick', isEqualTo: correo)
          .limit(1)
          .get();
      if (snap2.docs.isNotEmpty) {
        await addFavoritoPorDocId(snap2.docs.first.id, favorito);
        return;
      }
      throw Exception('Usuario no encontrado');
    }

    final docId = snapshot.docs.first.id;
    await addFavoritoPorDocId(docId, favorito);
  }

  Future<void> removeFavoritoPorDocId(String docId, String favorito) async {
    await _firestore.collection(collectionName).doc(docId).update({
      'listaFavoritos': FieldValue.arrayRemove([favorito])
    });
  }

  Future<void> removeFavoritoPorCorreo(String correo, String favorito) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      final snap2 = await _firestore
          .collection(collectionName)
          .where('nick', isEqualTo: correo)
          .limit(1)
          .get();
      if (snap2.docs.isNotEmpty) {
        await removeFavoritoPorDocId(snap2.docs.first.id, favorito);
        return;
      }
      throw Exception('Usuario no encontrado');
    }

    final docId = snapshot.docs.first.id;
    await removeFavoritoPorDocId(docId, favorito);
  }

  Future<void> setListaFavoritosPorDocId(
      String docId, List<String> lista) async {
    await _firestore.collection(collectionName).doc(docId).update({
      'listaFavoritos': lista,
    });
  }

  Future<void> addListaRegistro({
    required String idUsuario,
    required String idJuego,
    String? idSteam,
    String? idCheapshark,
    String? idTienda,
    String? title,
    String? thumb,
  }) async {
    final ref = _firestore.collection(listaCollection);

    final tienda = idTienda ?? "0";

    final docId = '${idUsuario}_${idJuego}_$tienda';

    final data = <String, dynamic>{
      'idUsuario': idUsuario,
      'idJuego': idJuego,
      'idTienda': tienda,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (idSteam != null) data['idSteam'] = idSteam;
    if (idCheapshark != null) data['idCheapshark'] = idCheapshark;
    if (title != null) data['title'] = title;
    if (thumb != null) data['thumb'] = thumb;

    await ref.doc(docId).set(data, SetOptions(merge: true));
  }

  Future<void> removeListaRegistro({
    required String idUsuario,
    required String idJuego,
    required String idTienda,
  }) async {
    final docId = '${idUsuario}_${idJuego}_$idTienda';

    try {
      await _firestore.collection(listaCollection).doc(docId).delete();
    } catch (_) {}
  }

  Future<List<String>> obtenerListaPorUsuarioId(String idUsuario) async {
    final snapshot = await _firestore
        .collection(listaCollection)
        .where('idUsuario', isEqualTo: idUsuario)
        .get();

    if (snapshot.docs.isEmpty) return [];
    return snapshot.docs
        .map((d) {
          final raw = d.data();
          if (raw is Map<String, dynamic>) {
            return (raw['idJuego'] ?? '').toString();
          } else {
            final map = Map<String, dynamic>.from(raw as Map);
            return (map['idJuego'] ?? '').toString();
          }
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerRegistrosListaPorUsuario(
      String idUsuario) async {
    final snapshot = await _firestore
        .collection(listaCollection)
        .where('idUsuario', isEqualTo: idUsuario)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((d) {
      final raw = d.data();
      if (raw is Map<String, dynamic>) {
        return raw;
      } else {
        return Map<String, dynamic>.from(raw as Map);
      }
    }).toList();
  }

  Future<List<String>> obtenerFavoritosPorCorreo(String correo) async {
    final List<String> result = [];

    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();

    QueryDocumentSnapshot? userDoc;
    if (snapshot.docs.isNotEmpty) {
      userDoc = snapshot.docs.first;
    } else {
      final snap2 = await _firestore
          .collection(collectionName)
          .where('nick', isEqualTo: correo)
          .limit(1)
          .get();
      if (snap2.docs.isNotEmpty) userDoc = snap2.docs.first;
    }

    String idUsuarioStr = '0';
    if (userDoc != null) {
      final rawData = userDoc.data();
      final data = (rawData is Map<String, dynamic>)
          ? rawData
          : Map<String, dynamic>.from(rawData as Map);

      final listaDoc = (data['listaFavoritos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      if (listaDoc != null) result.addAll(listaDoc);

      final idVal = data['id'];
      if (idVal != null) idUsuarioStr = idVal.toString();
    }

    if (idUsuarioStr != '0') {
      final listaDesdeColeccion = await obtenerListaPorUsuarioId(idUsuarioStr);
      result.addAll(listaDesdeColeccion);
    }

    return result.toSet().toList();
  }

  Future<Usuario?> signInWithGoogle(BuildContext context) async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    final firebaseUser = userCred.user;

    if (firebaseUser == null || firebaseUser.email == null) return null;

    final snap = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: firebaseUser.email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();

      if (!data.containsKey('id')) {
        throw Exception('Usuario sin ID en Firestore');
      }

      final usuario = Usuario.fromJson(data);

      UsuarioIniciado.iniciarSesion(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión iniciada correctamente')),
      );

      return usuario;
    }

    final nuevoId = await obtenerSiguienteId();

    final nuevoUsuario = Usuario(
      id: nuevoId,
      nick: firebaseUser.displayName ?? 'UsuarioGoogle',
      correo: firebaseUser.email!,
      contrasena: '',
      imagenRuta: firebaseUser.photoURL ?? 'default.png',
    );

    await addUsuario(nuevoUsuario);

    UsuarioIniciado.iniciarSesion(nuevoUsuario);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta creada y sesión iniciada')),
    );

    return nuevoUsuario;
  }

  Future<Usuario?> registrarConGoogle(BuildContext context) async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    final firebaseUser = userCred.user;

    if (firebaseUser == null || firebaseUser.email == null) return null;
    final snap = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: firebaseUser.email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe un usuario con esta cuenta')),
      );

      await _auth.signOut();

      return null;
    }
    final nuevoId = await obtenerSiguienteId();

    final nuevoUsuario = Usuario(
      id: nuevoId,
      nick: firebaseUser.displayName ?? 'UsuarioGoogle',
      correo: firebaseUser.email!,
      contrasena: '',
      imagenRuta: firebaseUser.photoURL ?? 'default.png',
    );

    await addUsuario(nuevoUsuario);

    UsuarioIniciado.iniciarSesion(nuevoUsuario);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta creada correctamente')),
    );

    return nuevoUsuario;
  }

  Future<bool> correoExiste(String correo) async {
    final snap = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> actualizarUsuario({
    required String correoActual,
    required String contrasena,
    required String nuevoNick,
    required String nuevoCorreo,
  }) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correoActual)
        .where('contrasena', isEqualTo: contrasena)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return false;
    }

    final docId = snapshot.docs.first.id;

    await _firestore.collection(collectionName).doc(docId).update({
      'nick': nuevoNick,
      'correo': nuevoCorreo,
    });

    return true;
  }

  Future<bool> verificarContrasena(String correo, String contrasena) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .where('contrasena', isEqualTo: contrasena)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> actualizarContrasena(String correo, String nueva) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final docId = snapshot.docs.first.id;

    await _firestore.collection(collectionName).doc(docId).update({
      'contrasena': nueva,
    });
  }

  Future<void> guardarNotificacion({
    required String idUser,
    required String idCheapshark,
    required String idSteam,
    required String idTienda,
    required String titulo,
    required String porcentajeDescuento,
    required String precioDeseado,
    required String tipoNotificacion,
  }) async {
    final docId = "${idUser}_${idCheapshark}_${idTienda}";

    await _firestore.collection("ListaNotificacionesPorUser").doc(docId).set({
      "IdUser": idUser,
      "IdCheapshark": idCheapshark,
      "IdSteam": idSteam,
      "idTienda": idTienda,
      "Titulo": titulo,
      "TipoNotificacion": tipoNotificacion,
      "porcentajeDescuento": porcentajeDescuento,
      "precioDeseado": precioDeseado,
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> obtenerNotificacionesUsuario(
      String idUsuario) async {
    final snapshot = await _firestore
        .collection("ListaNotificacionesPorUser")
        .where("IdUser", isEqualTo: idUsuario)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((d) {
      final raw = d.data();

      if (raw is Map<String, dynamic>) {
        return raw;
      } else {
        return Map<String, dynamic>.from(raw as Map);
      }
    }).toList();
  }

  Future<void> borrarNotificacion({
    required String idUser,
    required String idCheapshark,
    required String idTienda,
  }) async {
    final docId = "${idUser}_${idCheapshark}_${idTienda}";

    await _firestore
        .collection("ListaNotificacionesPorUser")
        .doc(docId)
        .delete();
  }

  Future<bool> obtenerEstadoNotificaciones(String idUsuario) async {
    final snapshot = await _firestore
        .collection("activarNotificacion")
        .where("idUsuario", isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final data = snapshot.docs.first.data();

    return (data["estado"] ?? false) == true;
  }

  Future<void> actualizarEstadoNotificaciones({
    required String idUsuario,
    required bool estado,
  }) async {
    final docId = idUsuario;

    await _firestore.collection("activarNotificacion").doc(docId).set({
      "idUsuario": idUsuario,
      "estado": estado,
    }, SetOptions(merge: true));
  }

  Future<bool> toggleEstadoNotificaciones(String idUsuario) async {
    final ref = _firestore.collection("activarNotificacion");

    final snapshot =
        await ref.where("idUsuario", isEqualTo: idUsuario).limit(1).get();

    if (snapshot.docs.isEmpty) {
      await ref.doc(idUsuario).set({
        "idUsuario": idUsuario,
        "estado": true,
      });

      return true;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    final estadoActual = (data["estado"] ?? false) == true;

    final nuevoEstado = !estadoActual;

    await ref.doc(doc.id).update({
      "estado": nuevoEstado,
    });

    return nuevoEstado;
  }

  Future<bool> borrarCuentaCompleta({
    required String correo,
    required String contrasena,
    required String idUsuario,
  }) async {
    try {
      final correcto = await verificarContrasena(correo, contrasena);
      if (!correcto) return false;
      final userSnap = await _firestore
          .collection(collectionName)
          .where("correo", isEqualTo: correo)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        await _firestore
            .collection(collectionName)
            .doc(userSnap.docs.first.id)
            .delete();
      }
      final listaSnap = await _firestore
          .collection(listaCollection)
          .where("idUsuario", isEqualTo: idUsuario)
          .get();

      for (var doc in listaSnap.docs) {
        await doc.reference.delete();
      }
      final notiSnap = await _firestore
          .collection("ListaNotificacionesPorUser")
          .where("IdUser", isEqualTo: idUsuario)
          .get();

      for (var doc in notiSnap.docs) {
        await doc.reference.delete();
      }
      final activarSnap = await _firestore
          .collection("activarNotificacion")
          .where("idUsuario", isEqualTo: idUsuario)
          .get();

      for (var doc in activarSnap.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      debugPrint("Error borrando cuenta: $e");
      return false;
    }
  }
}
