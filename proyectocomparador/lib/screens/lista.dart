import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/dataJuego.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';
import 'package:proyectocomparador/screens/detalleJuego.dart';
import 'package:proyectocomparador/widgets/widgesAdicionales.dart';

class ListaFavoritos extends StatefulWidget {
  final VoidCallback? onFavoritosActualizados;
  const ListaFavoritos({super.key, this.onFavoritosActualizados});

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

  static const Map<String, String> iconosTiendas = {
    "1": "https://www.cheapshark.com/img/stores/icons/0.png",
    "7": "https://www.cheapshark.com/img/stores/icons/6.png",
    "11": "https://www.cheapshark.com/img/stores/icons/10.png",
    "13": "https://www.cheapshark.com/img/stores/icons/12.png",
    "25": "https://www.cheapshark.com/img/stores/icons/24.png",
  };

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
            storeid: reg['idTienda'] ?? '',
          );

          resultados.add(juego);
          _favoriteIds.add("${juego.idCheapshark}_${juego.storeid}");
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
    final idJuego = juego.idCheapshark;
    final idTienda = juego.storeid;
    final key = "${idJuego}_$idTienda";

    if (esFavorito) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar favorito'),
          content: Text('¿Eliminar "${juego.title}" de la lista de deseados?'),
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
        _favoriteIds.add(key);
        _favoriteGames.add(juego);
      } else {
        _favoriteIds.remove(key);

        _favoriteGames.removeWhere(
          (g) => g.idCheapshark == idJuego && g.storeid == idTienda,
        );
      }
      widget.onFavoritosActualizados?.call();
    });

    final correo = UsuarioIniciado.usuario?.correo;
    if (correo == null) return;

    try {
      if (nuevoEstado) {
        await _fs.addFavoritoPorCorreo(correo, idJuego);

        await _fs.addListaRegistro(
          idUsuario: UsuarioIniciado.usuarioIdString,
          idJuego: idJuego,
          idSteam: juego.steamApiID,
          idCheapshark: juego.idCheapshark,
          idTienda: idTienda,
          title: juego.title,
          thumb: juego.thumb,
        );
      } else {
        try {
          await Future.wait([
            _fs.removeListaRegistro(
              idUsuario: UsuarioIniciado.usuarioIdString,
              idJuego: idJuego,
              idTienda: idTienda,
            ),
            _fs.removeFavoritoPorCorreo(correo, idJuego),
            _fs.borrarNotificacion(
              idUser: UsuarioIniciado.usuarioIdString,
              idCheapshark: idJuego,
              idTienda: idTienda,
            ),
          ]);
        } catch (e) {
          debugPrint("Error eliminando en paralelo: $e");
        }
      }
    } catch (e) {
      debugPrint("Error actualizando favorito: $e");
    }
  }

  Future<void> _handleTapJuego(Juego juego) async {
    if (_isEnriching) return;

    String gameId = juego.idCheapshark;

    Juego? enriched = juego;

    setState(() {
      _isEnriching = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (gameId.isNotEmpty) {
        final fetched = await _gestor.fetchByGameId(gameId, useCache: true);

        if (fetched != null) {
          enriched = fetched;
        } else {
          final raw = await _gestor.fetchRawByGameId(gameId);
          if (raw != null) {
            enriched = _rawToJuego(raw, gameId);
          }
        }
      }

      if (gameId.isNotEmpty) {}

      DataJuego? steamData;
      if (enriched.steamApiID.isNotEmpty) {
        steamData = await _gestor.fetchSteamGameData(
          enriched.steamApiID,
          useCache: true,
        );
      }

      if (Navigator.canPop(context)) Navigator.pop(context);

      final toSend = enriched;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleJuego(
            title: toSend.title,
            juego: toSend,
            steamData: steamData,
          ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      debugPrint("Error cargando detalle: $e");
    } finally {
      setState(() {
        _isEnriching = false;
      });
    }
  }

  Juego _rawToJuego(Map<String, dynamic> raw, String gameId) {
    try {
      final info = (raw['info'] is Map)
          ? Map<String, dynamic>.from(raw['info'])
          : Map<String, dynamic>.from(raw);

      final nombre =
          (info['title'] ?? info['name'] ?? info['nombre'] ?? '').toString();
      final thumb =
          (info['thumb'] ?? info['thumbnail'] ?? raw['thumb'] ?? '').toString();

      final precioBaseRaw =
          (raw['cheapest'] ?? raw['cheapestPrice'] ?? raw['price'] ?? '')
              .toString();

      double minimoHistorico = 0.0;
      final candidates = [
        raw['cheapest'],
        raw['cheapestPrice'],
        raw['lowest'],
        raw['price'],
        raw['historicLowest'],
        raw['minPrice'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString().replaceAll(',', '.').trim();
        final p = double.tryParse(s);
        if (p != null) {
          minimoHistorico = p;
          break;
        }
      }

      final fechaMin = (raw['cheapestTimestamp'] ??
              raw['cheapestDate'] ??
              raw['historicLowestDate'] ??
              raw['date'] ??
              '')
          .toString();

      final steamApiID =
          (info['steamAppID'] ?? info['steamApiID'] ?? '').toString();
      final steamRating = (info['steamRating'] ?? '').toString();
      (info['reviewCount'] ?? info['cuantasResenas'] ?? '').toString();
      final metaCriticsRating =
          (info['metacritic'] ?? info['metaCriticsRating'] ?? '').toString();
      final metacriticLink = (info['metacriticLink'] ?? '').toString();
      final fechaDeSalida =
          (info['releaseDate'] ?? info['release'] ?? '').toString();
      final idTienda = (info['storeID'] ?? info['storeID'] ?? '').toString();

      return Juego(
        idCheapshark: gameId,
        title: nombre.isNotEmpty ? nombre : 'Sin título',
        steamApiID: steamApiID,
        normalPrice: precioBaseRaw,
        steamRatingCount: steamRating,
        steamRatingPercent: steamRating,
        metaCriticScore: metaCriticsRating,
        metacriticLink: metacriticLink,
        releaseDate: fechaDeSalida,
        thumb: thumb,
        minimoHistorico: minimoHistorico,
        fechaMinimoHistorico: fechaMin,
        listaPorTienda: <DatoJuegoPorTienda>[],
        storeid: idTienda,
      );
    } catch (e, st) {
      debugPrint('Error mapeando raw a Juego: $e');
      debugPrint(st.toString());
      return Juego(
        idCheapshark: gameId,
        title: raw.toString(),
        steamApiID: '',
        normalPrice: '0',
        steamRatingCount: '',
        steamRatingPercent: '',
        metaCriticScore: '',
        metacriticLink: '',
        releaseDate: '',
        thumb: '',
        minimoHistorico: 0.0,
        fechaMinimoHistorico: '',
        listaPorTienda: [],
        storeid: '',
      );
    }
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
      iconosTiendas: iconosTiendas,
      onFavoritePressed: _handleFavoritePressed,
      onTapJuego: _handleTapJuego,
    );
  }
}
