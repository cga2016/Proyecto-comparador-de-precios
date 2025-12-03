import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectocomparador/models/usuario.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  final String collectionName = 'user';
  final String contadorDocPath = 'contadores/usuarios';

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
        final data = snapshot.data() as Map<String, dynamic>;
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
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .where('contrasena', isEqualTo: contrasena)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      final usuario = Usuario.fromJson(data);
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

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      await addFavoritoPorDocId(docId, favorito);
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  Future<List<String>> obtenerFavoritosPorCorreo(String correo) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('correo', isEqualTo: correo)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final lista = (data['listaFavoritos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      return lista ?? [];
    } else {
      return [];
    }
  }
}
