// ignore_for_file: unnecessary_type_check

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectocomparador/models/usuario.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  final String collectionName = 'user';
  final String contadorDocPath = 'contadores/usuarios';
  final String listaCollection = 'lista';

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

  Future<bool> correoExiste(String correo) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Operaciones en user.listaFavoritos
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
    String? title,
    String? thumb,
  }) async {
    final ref = _firestore.collection(listaCollection);
    final docId = '${idUsuario}_$idJuego';

    final data = <String, dynamic>{
      'idUsuario': idUsuario,
      'idJuego': idJuego,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // añadimos campos extra si se proporcionan
    if (idSteam != null) data['idSteam'] = idSteam;
    if (idCheapshark != null) data['idCheapshark'] = idCheapshark;
    if (title != null) data['title'] = title;
    if (thumb != null) data['thumb'] = thumb;

    await ref.doc(docId).set(data, SetOptions(merge: true));
  }

  Future<void> removeListaRegistro(
      {required String idUsuario, required String idJuego}) async {
    final docId = '${idUsuario}_$idJuego';
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
}
