import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';
import 'package:proyectocomparador/screens/notificacionesOpciones.dart';

class UsuarioPerfil extends StatefulWidget {
  const UsuarioPerfil({super.key});

  @override
  State<UsuarioPerfil> createState() => _UsuarioPerfilState();
}

class _UsuarioPerfilState extends State<UsuarioPerfil> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final FirestoreService firestore = FirestoreService();

  @override
  void initState() {
    super.initState();

    final usuario = UsuarioIniciado.usuario;

    if (usuario != null) {
      nombreController.text = usuario.nick;
      correoController.text = usuario.correo;
    }
  }

  void guardarCambios() {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) return;

    if (nombreController.text == usuario.nick &&
        correoController.text == usuario.correo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se han realizado cambios")),
      );

      return;
    }

    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar cambios"),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Introduce tu contraseña",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final correcto = await firestore.actualizarUsuario(
                  correoActual: usuario.correo,
                  contrasena: passController.text,
                  nuevoNick: nombreController.text,
                  nuevoCorreo: correoController.text,
                );

                Navigator.pop(context);

                if (correcto) {
                  usuario.nick = nombreController.text;
                  usuario.correo = correoController.text;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Datos actualizados")),
                  );

                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contraseña incorrecta")),
                  );
                }
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  void _borrarCuenta() {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) return;

    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar cuenta"),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Introduce tu contraseña",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Eliminar"),
              onPressed: () async {
                final ok = await firestore.borrarCuentaCompleta(
                  correo: usuario.correo,
                  contrasena: passController.text,
                  idUsuario: UsuarioIniciado.usuarioIdString,
                );

                Navigator.pop(context);

                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Contraseña incorrecta"),
                    ),
                  );
                  return;
                }

                /// 🔥 CERRAR SESIÓN
                UsuarioIniciado.cerrarSesion();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cuenta eliminada correctamente"),
                  ),
                );

                /// 🔥 VOLVER AL LOGIN (ajusta ruta si tienes otra)
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.pushReplacementNamed(
                    context, "/screen/iniciarSesion");
              },
            ),
          ],
        );
      },
    );
  }

  void cambiarContrasena() {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) return;

    final actualController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Contraseña actual"),
          content: TextField(
            controller: actualController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Introduce tu contraseña actual",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              child: const Text("Continuar"),
              onPressed: () async {
                bool correcta = await firestore.verificarContrasena(
                    usuario.correo, actualController.text);

                Navigator.pop(context);

                if (!correcta) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contraseña incorrecta")),
                  );

                  return;
                }
                final nuevaController = TextEditingController();
                final repetirController = TextEditingController();

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Nueva contraseña"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nuevaController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Nueva contraseña",
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: repetirController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Confirmar contraseña",
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        ElevatedButton(
                          child: const Text("Cambiar"),
                          onPressed: () async {
                            if (nuevaController.text !=
                                repetirController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Las contraseñas no coinciden"),
                                ),
                              );

                              return;
                            }

                            await firestore.actualizarContrasena(
                                usuario.correo, nuevaController.text);

                            usuario.contrasena = nuevaController.text;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Contraseña actualizada"),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioIniciado.usuario;

    if (usuario == null) {
      return const Center(
        child: Text(
          'No hay sesión iniciada',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perfil de usuario',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10002B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTextField(
                  label: 'Nombre',
                  controller: nombreController,
                ),
                _buildTextField(
                  label: 'Correo',
                  controller: correoController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: guardarCambios,
              icon: const Icon(Icons.save, color: Colors.black), // 🔥 ICONO
              label: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC77DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: cambiarContrasena,
              icon: const Icon(Icons.lock, color: Colors.black),
              label: const Text(
                "Modificar contraseña",
                style: TextStyle(color: Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFC77DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.white30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificacionesOpciones(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications, color: Colors.black),
              label: const Text(
                "Configurar notificaciones",
                style: TextStyle(color: Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFC77DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.white30),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _borrarCuenta,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text(
                "Borrar cuenta",
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.white30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
