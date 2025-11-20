// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/juego.dart';

class DetalleJuego extends StatefulWidget {
  const DetalleJuego({super.key, required this.title, required this.juego});

  final String title;
  final Juego juego;

  @override
  State<DetalleJuego> createState() => _DetalleJuegoState();
}

class _DetalleJuegoState extends State<DetalleJuego> {
  @override
  Widget build(BuildContext context) {
    final juego = widget.juego;

    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A189A),
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen grande (si existe) - fallback a imagen pequeña
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: (juego.urlImagenGrande.isNotEmpty
                              ? juego.urlImagenGrande
                              : juego.urlImagenPequena)
                          .isNotEmpty
                      ? Image.network(
                          juego.urlImagenGrande.isNotEmpty
                              ? juego.urlImagenGrande
                              : juego.urlImagenPequena,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.videogame_asset,
                                  color: Colors.white, size: 48),
                            ),
                          ),
                        )
                      : Container(
                          height: 220,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.videogame_asset,
                                color: Colors.white, size: 48),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Título
              Text(
                juego.titulo,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Precio y review
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Precio actual: ${_formatPrice(juego.precioActual)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Precio mínimo: ${_formatPrice(juego.precioMinimo)}',
                          style: const TextStyle(
                              color: Colors.greenAccent, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Review: ${juego.review.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('Desarrollador: ${juego.desarrollador}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 16),

              // Descripción
              _buildSectionTitle('Descripción'),
              Text(
                  juego.descripcion.isNotEmpty
                      ? juego.descripcion
                      : 'No disponible',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),

              const SizedBox(height: 16),

              // Otros datos estructurados
              _buildDetailRow('ID', juego.id),
              _buildDetailRow('URL imagen pequeña', juego.urlImagenPequena),
              _buildDetailRow('URL imagen grande', juego.urlImagenGrande),

              const SizedBox(height: 24),

              // Botones Añadir y Precios
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Por ahora sin funcionalidad (placeholder)
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Añadir (sin función).')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A189A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Añadir',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Placeholder para "Precios"
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Precios (sin función).')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A189A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Precios',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Debug: vista rápida del objeto
              Text('Datos raw: ${juego.toJson()}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(title,
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value.isNotEmpty ? value : 'No disponible',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price <= 0) return 'Gratis';
    return price.toStringAsFixed(2);
  }
}
