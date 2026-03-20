import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/sesionUsuario.dart';
import 'package:proyectocomparador/screens/mostrarNotificaciones.dart';

class TopBar extends StatelessWidget {
  final bool tieneNotificaciones;

  const TopBar({super.key, required this.tieneNotificaciones});

  @override
  Widget build(BuildContext context) {
    final usuario = SesionUsuario.usuarioActual;

    String nick = usuario?.nick ?? "Invitado";

    if (nick.length > 30) {
      nick = "${nick.substring(0, 27)}...";
    }

    /*
    if (nick.length > 30) {
      nick = nick.substring(0, 27) + "...";
    }*/

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF3C096C),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            nick,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Stack(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MostrarNotificaciones(),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.notifications,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (tieneNotificaciones)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          "!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    SesionUsuario.cerrarSesion();
                    Navigator.pushReplacementNamed(
                        context, "/screen/iniciarSesion");
                  },
                  child: const Icon(
                    Icons.logout,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
