import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';
import 'package:proyectocomparador/screens/detalleJuego.dart';
import 'package:proyectocomparador/widgets/widgesAdicionales.dart';

class ListaFavoritos extends StatefulWidget {
  const ListaFavoritos({super.key});

  @override
  State<ListaFavoritos> createState() => _ListaFavoritosState();
}

class _ListaFavoritosState extends State<ListaFavoritos> {
  final FirestoreService _fs = FirestoreService();
  final CheapSharkGestor _gestor = CheapSharkGestor();

  bool _isSearching = false;
  bool _isEnriching = false;

  final Set<String> _favoriteIds = {};
  List<Juego> _favoriteGames = [];

  @override
  void initState() {
    super.initState();
    _loadUserFavoritesIfLogged();
  }

  @override
  void dispose() {
    _gestor.dispose();
    super.dispose();
  }

  Future<void> _loadUserFavoritesIfLogged() async {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) return;

    final correo = usuario.correo;
    final ids = await _fs.obtenerFavoritosPorCorreo(correo);

    setState(() {
      _favoriteIds
        ..clear()
        ..addAll(ids);
    });

    await _loadFavoriteGames();
  }

  Future<void> _loadFavoriteGames() async {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) return;

    setState(() {
      _isSearching = true;
      _favoriteGames = [];
    });

    try {
      final registros = await _fs
          .obtenerRegistrosListaPorUsuario(UsuarioIniciado.usuarioIdString);

      final List<Juego> resultados = [];

      if (registros.isNotEmpty) {
        for (final reg in registros) {
          final juego = Juego(
            idCheapshark: reg['idCheapshark'] ?? reg['idJuego'],
            title: reg['title'] ?? 'Sin título',
            thumb: reg['thumb'] ?? '',
            steamApiID: reg['idSteam'] ?? '',
            normalPrice: '0',
            steamRatingCount: '',
            steamRatingPercent: '',
            metaCriticScore: '',
            metacriticLink: '',
            releaseDate: '',
            minimoHistorico: 0,
            fechaMinimoHistorico: '',
            listaPorTienda: <DatoJuegoPorTienda>[],
          );

          resultados.add(juego);
          _favoriteIds.add(juego.idCheapshark);
        }
      }

      setState(() => _favoriteGames = resultados);
    } catch (_) {
      setState(() => _favoriteGames = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _handleFavoritePressed(
      BuildContext context, Juego juego, bool esFavorito) async {
    final juegoId = juego.idCheapshark;

    if (esFavorito) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar favorito'),
          content: Text('¿Eliminar "${juego.title}" de favoritos?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar')),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    final nuevoEstado = !esFavorito;

    setState(() {
      if (nuevoEstado) {
        _favoriteIds.add(juegoId);
        _favoriteGames.add(juego);
      } else {
        _favoriteIds.remove(juegoId);
        _favoriteGames.removeWhere((g) => g.idCheapshark == juegoId);
      }
    });

    final correo = UsuarioIniciado.usuario?.correo;
    if (correo == null) return;

    if (nuevoEstado) {
      await _fs.addFavoritoPorCorreo(correo, juegoId);
    } else {
      await _fs.removeFavoritoPorCorreo(correo, juegoId);
    }
  }

  Future<void> _handleTapJuego(Juego juego) async {
    if (_isEnriching) return;
    _isEnriching = true;

    Juego enriched = juego;

    final fetched =
        await _gestor.fetchByGameId(juego.idCheapshark, useCache: true);
    if (fetched != null) enriched = fetched;

    _isEnriching = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleJuego(title: enriched.title, juego: enriched),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteGames.isEmpty) {
      return const Center(
        child: Text('No tienes juegos favoritos',
            style: TextStyle(color: Colors.white70)),
      );
    }

    return FavoritesListView(
      isSearching: _isSearching,
      favoriteGames: _favoriteGames,
      favoriteIds: _favoriteIds,
      onFavoritePressed: _handleFavoritePressed,
      onTapJuego: _handleTapJuego,
    );
  }
}
