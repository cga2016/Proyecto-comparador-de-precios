import 'package:flutter/material.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/widgets/jeugoWidgetBuscador.dart';

class BuscadorWidget extends StatefulWidget {
  final Set<String> favoriteIds;
  final Future<void> Function(
    BuildContext context,
    Juego juego,
    bool esFavorito,
  ) onFavoritePressed;

  final Future<void> Function(Juego juego) onTapJuego;

  const BuscadorWidget({
    super.key,
    required this.favoriteIds,
    required this.onFavoritePressed,
    required this.onTapJuego,
  });

  @override
  State<BuscadorWidget> createState() => _BuscadorWidgetState();
}

class _BuscadorWidgetState extends State<BuscadorWidget> {
  final TextEditingController _searchController = TextEditingController();
  final CheapSharkGestor _gestor = CheapSharkGestor();

  bool _isSearching = false;
  List<Juego> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _gestor.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      final resultados = await _gestor.searchByTitle(query, limit: 20);
      setState(() => _searchResults = resultados);
    } catch (e) {
      debugPrint('Error en búsqueda: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al buscar juegos')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Buscar juego por título...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                ),
                IconButton(
                  onPressed: _isSearching ? null : _buscar,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isSearching && _searchResults.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final juego = _searchResults[index];
                    final esFavorito =
                        widget.favoriteIds.contains(juego.idCheapshark);

                    return GameTile(
                      juego: juego,
                      isFavorito: esFavorito,
                      priceText: juego.normalPrice,
                      minText: juego.minimoHistorico.toStringAsFixed(2),
                      onTap: () => widget.onTapJuego(juego),
                      onFavoriteToggle: (_) async {
                        await widget.onFavoritePressed(
                            context, juego, esFavorito);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
