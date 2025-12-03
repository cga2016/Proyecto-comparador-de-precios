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

    // elegir imagen: usamos thumb (la API nueva sólo expone thumb en tu modelo)
    final imageUrl = (juego.thumb.isNotEmpty) ? juego.thumb : '';

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
              // Imagen grande (si existe) sino placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
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

              // Título (nombre)
              Text(
                juego.nombre.isNotEmpty ? juego.nombre : 'Sin título',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Precio y datos básicos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Columna izquierda: precio actual (precioBase) y mínimo histórico
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Precio actual: ${_formatPriceFromStringOrDouble(juego.precioBase, juego.minimoHistorico)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                          'Precio mínimo histórico: ${_formatPriceDouble(juego.minimoHistorico)}',
                          style: const TextStyle(
                              color: Colors.greenAccent, fontSize: 14)),
                    ],
                  ),

                  // Columna derecha: algunos metadatos si existen
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          'Steam ID: ${juego.steamApiID.isNotEmpty ? juego.steamApiID : 'No disponible'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                          'Publisher: ${juego.publisher.isNotEmpty ? juego.publisher : 'No disponible'}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildSectionTitle('Descripción'),
              // El modelo actual no tiene campo 'descripcion' en tu definición; mostramos fallback
              Text(
                'No disponible',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),

              const SizedBox(height: 16),

              _buildDetailRow('ID CheapShark', juego.idCheapshark),
              _buildDetailRow('ID interno', juego.id),
              _buildDetailRow('URL imagen (thumb)', juego.thumb),
              _buildDetailRow('Precio base (raw)', juego.precioBase),
              _buildDetailRow(
                  'Fecha mínimo histórico', juego.fechaMinimoHistorico),

              const SizedBox(height: 24),

              // Si listaPorTienda tiene datos, mostramos un resumen
              if (juego.listaPorTienda.isNotEmpty) ...[
                _buildSectionTitle('Precios por tienda'),
                _buildTiendasList(),
                const SizedBox(height: 24),
              ],

              // Botones Añadir y Precios
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
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

              // Datos raw (mapa)
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

  // Muestra listaPorTienda en forma compacta. Requiere que DatoJuegoPorTienda tenga toJson() implementado.
  Widget _buildTiendasList() {
    final lista = widget.juego.listaPorTienda;
    return Column(
      children: lista.map((d) {
        final map = d.toJson();
        final tienda = map['storeName'] ?? map['store'] ?? 'Tienda';
        final price = map['price']?.toString() ?? '-';
        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            title: Text(tienda.toString(),
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('Precio: $price',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  String _formatPriceDouble(double price) {
    try {
      if (price.isNaN) return '-';
      if (price <= 0) return 'Gratis';
      return price.toStringAsFixed(2);
    } catch (_) {
      return '-';
    }
  }

  String _formatPriceFromStringOrDouble(
      String precioBase, double minimoHistorico) {
    // precioBase viene como String en el modelo; intentamos parsearlo.
    final parsed = _tryParseDouble(precioBase);
    if (parsed != null) {
      if (parsed <= 0) return 'Gratis';
      return parsed.toStringAsFixed(2);
    }

    // fallback a minimoHistorico
    if (minimoHistorico > 0) return minimoHistorico.toStringAsFixed(2);

    return 'No disponible';
  }

  double? _tryParseDouble(String? s) {
    if (s == null) return null;
    final clean = s.replaceAll(',', '.').trim();
    try {
      return double.parse(clean);
    } catch (_) {
      return null;
    }
  }
}
