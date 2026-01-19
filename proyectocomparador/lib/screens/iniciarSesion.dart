import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/models/sesionUsuario.dart';
import 'package:proyectocomparador/models/usuario.dart';

class IniciarSesion extends StatefulWidget {
  const IniciarSesion({super.key, required this.title});

  final String title;

  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

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
                "Inicio de sesión",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              _campoTexto('Correo', _correoController,
                  tipo: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _campoTexto('Contraseña', _contrasenaController,
                  esContrasena: true),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FloatingActionButton.extended(
                    label: const Text(
                      "Log in",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF3C096C),
                    onPressed: _iniciarSesion,
                    tooltip: 'Iniciar sesión',
                  ),
                  const SizedBox(width: 30),
                  FloatingActionButton.extended(
                    label: const Text(
                      "Registrar",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF3C096C),
                    onPressed: () {
                      _cambiar('/screen/registroUsuarios');
                    },
                    tooltip: 'Ir a registro',
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

  Future<void> _iniciarSesion() async {
    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos.")),
      );
      return;
    }

    final resultado = await firestoreService.buscarUsuario(correo, contrasena);

    if (resultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo o contraseña incorrectos.")),
      );
      return;
    }

    final Usuario usuario = resultado['usuario'];

    SesionUsuario.iniciarSesion(usuario);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bienvenido, ${usuario.nick}!")),
    );

    _cambiar('/screen/menuPrincipal');
  }

  void _cambiar(String ruta) {
    Navigator.pushReplacementNamed(context, ruta);
  }
}
