// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

class IniciarSesion extends StatefulWidget {
  const IniciarSesion({super.key, required this.title});

  final String title;

  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  // final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      body: Center(
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
                  onPressed: () {
                    _cambiar('/screen/menuPrincipal');
                  }, //_iniciarSesion,
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

  /* Future<void> _iniciarSesion() async {
    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text.trim();

//final usuario = await firestoreService.buscarUsuario(correo, contrasena);

/*if (usuario != null) {
      UsuarioIniciado.iniciarSesion(usuario);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso')),
      );
      _cambiar('/screen/menuPrincipal');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo o contraseña incorrectos')),
      );
    }*/
  }*/

  void _cambiar(String ruta) {
    Navigator.pop(context);
    Navigator.pushNamed(context, ruta);
  }
}
