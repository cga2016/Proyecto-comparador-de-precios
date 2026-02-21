import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';

class UsuarioPerfil extends StatelessWidget {
  const UsuarioPerfil({super.key});

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
          _buildTextField(
            label: 'Nombre',
            initialValue: usuario.nick,
          ),
          _buildTextField(
            label: 'Correo',
            initialValue: usuario.correo,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC77DFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: initialValue),
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
