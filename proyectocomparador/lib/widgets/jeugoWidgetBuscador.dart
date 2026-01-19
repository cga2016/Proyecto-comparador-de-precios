import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/juego.dart';

class GameTile extends StatelessWidget {
  final Juego juego;
  final bool isFavorito;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavoriteToggle;
  final String priceText; // texto ya formateado para el precio
  final String minText; // texto ya formateado para el mínimo histórico

  const GameTile({
    super.key,
    required this.juego,
    required this.isFavorito,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.priceText,
    required this.minText,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = juego.thumb;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2A2A2A),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 54,
                  child: (thumb.isNotEmpty)
                      ? Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.videogame_asset,
                                color: Colors.white),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.videogame_asset,
                              color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      juego.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Precio: $priceText',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Min: $minText',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onFavoriteToggle(!isFavorito),
                icon: Icon(
                  isFavorito ? Icons.star : Icons.star_border,
                  color: isFavorito ? Colors.yellow : Colors.white,
                ),
                tooltip: isFavorito ? 'Quitar favorito' : 'Añadir a favoritos',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
