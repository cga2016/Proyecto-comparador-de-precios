import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/juego.dart';

class GameTile extends StatelessWidget {
  final Juego juego;
  final bool isFavorito;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavoriteToggle;
  final String priceText;
  final String minText;

  const GameTile({
    super.key,
    required this.juego,
    required this.isFavorito,
    required this.priceText,
    required this.minText,
    required this.onTap,
    required this.onFavoriteToggle,
    String? storeIcon,
  });

  static const Map<String, String> iconosTiendas = {
    "1": "https://www.cheapshark.com/img/stores/icons/0.png",
    "7": "https://www.cheapshark.com/img/stores/icons/6.png",
    "11": "https://www.cheapshark.com/img/stores/icons/10.png",
    "13": "https://www.cheapshark.com/img/stores/icons/12.png",
    "25": "https://www.cheapshark.com/img/stores/icons/24.png",
  };

  @override
  Widget build(BuildContext context) {
    final thumb = juego.thumb;

    final String? iconUrl = iconosTiendas[juego.storeid];

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            juego.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (iconUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Image.network(
                              iconUrl,
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.store,
                                      color: Colors.white, size: 18),
                            ),
                          ),
                      ],
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
              if (priceText != minText)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Oferta: $minText',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
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
