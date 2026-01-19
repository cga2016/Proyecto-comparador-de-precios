// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/models/usuario.dart';

class RegistroUsuario extends StatefulWidget {
  const RegistroUsuario({super.key, required this.title});

  final String title;

  @override
  State<RegistroUsuario> createState() => _RegistroUsuarioState();
}

class _RegistroUsuarioState extends State<RegistroUsuario> {
  final TextEditingController _nickController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  @override
  void dispose() {
    _nickController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "Registro de usuarios",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              _campoTexto('Nick', _nickController),
              const SizedBox(height: 20),
              _campoTexto('Correo', _correoController,
                  tipo: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _campoTexto('Contraseña', _contrasenaController,
                  esContrasena: true),
              const SizedBox(height: 20),
              _campoTexto('Confirmar contraseña', _confirmController,
                  esContrasena: true),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FloatingActionButton.extended(
                    label: const Text("Registrar",
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                    backgroundColor: const Color(0xFF5A189A),
                    onPressed: _registrarUsuario,
                    tooltip: 'Registrar usuario',
                  ),
                  const SizedBox(width: 30),
                  FloatingActionButton.extended(
                    label: const Text("Regresar",
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                    backgroundColor: const Color(0xFF5A189A),
                    onPressed: () {
                      _cambiar('/screen/iniciarSesion');
                    },
                    tooltip: 'Volver a Log in',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(String label, TextEditingController controller,
      {TextInputType tipo = TextInputType.text, bool esContrasena = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: const Color.fromARGB(60, 255, 255, 255),
        ),
        keyboardType: tipo,
        obscureText: esContrasena,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  void _cambiar(String ruta) {
    Navigator.pop(context);
    Navigator.pushNamed(context, ruta);
  }

  Future<void> _registrarUsuario() async {
    final nick = _nickController.text.trim();
    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text.trim();
    final confirmar = _confirmController.text.trim();

    final List<String> faltan = [];
    if (nick.isEmpty) faltan.add('Nick');
    if (correo.isEmpty) faltan.add('Correo');
    if (contrasena.isEmpty) faltan.add('Contraseña');
    if (confirmar.isEmpty) faltan.add('Confirmar contraseña');

    if (faltan.isNotEmpty) {
      final texto = 'Por favor completa: ${faltan.join(', ')}.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texto)),
      );
      return;
    }

    if (contrasena != confirmar) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    try {
      final existe = await firestoreService.correoExiste(correo);
      if (existe) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El correo ya está registrado.')),
        );
        return;
      }

      final nuevoId = await firestoreService.obtenerSiguienteId();

      final nuevoUsuario = Usuario(
        id: nuevoId,
        nick: nick,
        correo: correo,
        contrasena: contrasena,
        imagenRuta: 'default.png',
      );

      await firestoreService.addUsuario(nuevoUsuario);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente.')),
      );

      _nickController.clear();
      _correoController.clear();
      _contrasenaController.clear();
      _confirmController.clear();
      _cambiar('/screen/iniciarSesion');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Firebase: ${e.code} - ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: ${e.toString()}')),
      );
    }
  }
}
