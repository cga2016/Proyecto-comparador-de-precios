import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectocomparador/models/usuarios.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda un usuario
  Future<void> addUsuario(Usuario usuario) async {
    await _firestore.collection('user').add({
      'name': usuario.name,
      'correo': usuario.correo,
      'contraseña': usuario.contrasena,
    });
  }

  /// Busca un usuario por correo y contraseña
  Future<Usuario?> buscarUsuario(String correo, String contrasena) async {
    final snapshot = await _firestore
        .collection('user')
        .where('correo', isEqualTo: correo)
        .where('contraseña', isEqualTo: contrasena)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return Usuario.fromMap(data);
    } else {
      return null;
    }
  }
}
