import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/sesionUsuario.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = SesionUsuario.usuarioActual;

    String nick = usuario?.nick ?? "Invitado";

    if (nick.length > 30) {
      nick = nick.substring(0, 27) + "...";
    }

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

          // 👇 MouseRegion para cambiar cursor
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
    );
  }
}
