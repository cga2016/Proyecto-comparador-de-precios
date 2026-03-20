import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/models/sesionUsuario.dart';

class IniciarSesion extends StatefulWidget {
  const IniciarSesion({super.key, required this.title});
  final String title;

  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();

  static const Color botonColor = Color(0xFF9D4EDD);
  static const Color botonColorPressed = Color(0xFFB185FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/icon/logoComparador.png',
                  height: 80,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Inicio de sesión",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _campoTexto('Correo o Nick', _correoController),
              const SizedBox(height: 20),
              _campoTexto(
                'Contraseña',
                _contrasenaController,
                esContrasena: true,
              ),
              const SizedBox(height: 30),
              _boton(
                texto: "Log in",
                onPressed: _loginNormal,
              ),
              const SizedBox(height: 15),
              _botonGoogle(),
              const SizedBox(height: 15),
              _boton(
                texto: "Registrar",
                onPressed: () =>
                    Navigator.pushNamed(context, '/screen/registroUsuarios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller, {
    bool esContrasena = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TextFormField(
        controller: controller,
        obscureText: esContrasena,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white24,
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _boton({
    required String texto,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (states) {
              if (states.contains(MaterialState.pressed)) {
                return botonColorPressed;
              }
              return botonColor;
            },
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _botonGoogle() {
    return SizedBox(
      width: 250,
      height: 48,
      child: ElevatedButton(
        onPressed: _loginGoogle,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.grey.shade300;
              }
              return Colors.white;
            },
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/google.png',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              'Entrar con Google',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginNormal() async {
    final res = await firestoreService.buscarUsuario(
      _correoController.text.trim(),
      _contrasenaController.text.trim(),
    );

    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales incorrectas')),
      );
      return;
    }

    SesionUsuario.iniciarSesion(res['usuario']);
    Navigator.pushReplacementNamed(context, '/screen/menuPrincipal');
  }

  Future<void> _loginGoogle() async {
    final usuario = await firestoreService.signInWithGoogle(context);
    if (usuario == null) return;

    SesionUsuario.iniciarSesion(usuario);
    Navigator.pushReplacementNamed(context, '/screen/menuPrincipal');
  }
}
