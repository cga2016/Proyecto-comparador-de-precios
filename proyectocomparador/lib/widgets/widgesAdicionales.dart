// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/juego.dart';

typedef FavoriteToggleCallback = Future<void> Function(
    BuildContext context, Juego juego, bool esFavorito);
typedef JuegoTapCallback = void Function(Juego juego);

class FavoritesListView extends StatelessWidget {
  final bool isSearching;
  final List<Juego> favoriteGames;
  final Set<String> favoriteIds;
  final FavoriteToggleCallback onFavoritePressed;
  final JuegoTapCallback onTapJuego;

  const FavoritesListView({
    super.key,
    required this.isSearching,
    required this.favoriteGames,
    required this.favoriteIds,
    required this.onFavoritePressed,
    required this.onTapJuego,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favoriteGames.isEmpty) {
      return const Center(
        child: Text(
          'No tienes favoritos aún',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      color: const Color(0xFF7B2CBF), // FONDO DE LA LISTA
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListView.builder(
          itemCount: favoriteGames.length,
          itemBuilder: (context, index) {
            final juego = favoriteGames[index];
            final juegoId = juego.idCheapshark.toString();
            final esFavorito = favoriteIds.contains(juegoId);

            return Card(
              color: const Color(0xFF10002B), // FONDO DE CADA ITEM
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: juego.thumb.isNotEmpty
                      ? Image.network(
                          juego.thumb,
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) {
                            return Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey,
                              child: const Icon(Icons.videogame_asset),
                            );
                          },
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey,
                          child: const Icon(Icons.videogame_asset),
                        ),
                ),
                title: Text(
                  juego.title,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: Icon(
                    esFavorito ? Icons.star : Icons.star_border,
                    color: esFavorito ? const Color(0xFFC77DFF) : Colors.white,
                  ),
                  onPressed: () =>
                      onFavoritePressed(context, juego, esFavorito),
                ),
                onTap: () => onTapJuego(juego),
              ),
            );
          },
        ),
      ),
    );
  }
}
