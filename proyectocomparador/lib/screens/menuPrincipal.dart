import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';
import 'package:proyectocomparador/screens/buscador.dart';
import 'package:proyectocomparador/screens/detalleJuego.dart';
import 'package:proyectocomparador/screens/lista.dart';
import 'package:proyectocomparador/widgets/appBarMenuPrincipal.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key, required this.title});

  final String title;

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final CheapSharkGestor _gestor = CheapSharkGestor();
  final FirestoreService _fs = FirestoreService();

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
    _searchController.dispose();
    _gestor.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      _loadFavoriteGames();
    }
  }

  Future<void> _loadUserFavoritesIfLogged() async {
    try {
      final usuario = UsuarioIniciado.usuario;
      if (usuario == null) {
        return;
      }

      final correo = usuario.correo;
      final lista = await _fs.obtenerFavoritosPorCorreo(correo);

      if (mounted) {
        setState(() {
          _favoriteIds.clear();
          _favoriteIds.addAll(lista);
        });
      } else {
        _favoriteIds.clear();
        _favoriteIds.addAll(lista);
      }

      await _loadFavoriteGames();
    } catch (e, st) {
      debugPrint('Error cargando favoritos del usuario: $e');
      debugPrint(st.toString());
    } finally {}
  }

  Future<void> _loadFavoriteGames() async {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) {
      if (mounted) {
        setState(() {
          _favoriteGames = [];
        });
      } else {
        _favoriteGames = [];
      }
      return;
    }

    final idUsuarioStr = UsuarioIniciado.usuarioIdString;
    if (idUsuarioStr == '0' || idUsuarioStr.isEmpty) {
      if (mounted) {
        setState(() {
          _favoriteGames = [];
        });
      } else {
        _favoriteGames = [];
      }
      return;
    }

    if (mounted) {
      setState(() {
        _favoriteGames = [];
      });
    } else {
      _favoriteGames = [];
    }

    try {
      List<Map<String, dynamic>> registros = [];
      try {
        registros = await _fs.obtenerRegistrosListaPorUsuario(idUsuarioStr);
      } catch (e) {
        debugPrint('obtenerRegistrosListaPorUsuario no disponible o falló: $e');
      }

      final List<Juego> resultados = [];

      if (registros.isNotEmpty) {
        for (final reg in registros) {
          try {
            final idJuego = (reg['idJuego'] ?? '').toString();
            final title = (reg['title'] ?? '').toString();
            final thumb = (reg['thumb'] ?? '').toString();
            final idCheap = (reg['idCheapshark'] ?? '').toString();
            final idSteam = (reg['idSteam'] ?? '').toString();

            final juego = Juego(
              idCheapshark: idCheap.isNotEmpty ? idCheap : idJuego,
              title: title.isNotEmpty ? title : 'Sin título',
              steamApiID: idSteam,
              normalPrice: '0',
              steamRatingCount: '',
              steamRatingPercent: '',
              metaCriticScore: '',
              metacriticLink: '',
              releaseDate: '',
              thumb: thumb,
              minimoHistorico: 0.0,
              fechaMinimoHistorico: '',
              listaPorTienda: <DatoJuegoPorTienda>[],
            );

            if (!resultados.any((j) => j.idCheapshark == juego.idCheapshark)) {
              resultados.add(juego);
            }
            _favoriteIds.add(idJuego);
          } catch (e, st) {
            debugPrint('Error mapeando registro lista a Juego: $e');
            debugPrint(st.toString());
          }
        }
      } else {
        final correo = usuario.correo;
        final ids = await _fs.obtenerFavoritosPorCorreo(correo);
        for (final id in ids) {
          try {
            final juegoFromApi =
                await _gestor.fetchByGameId(id, useCache: true);
            if (juegoFromApi != null) {
              if (!resultados
                  .any((j) => j.idCheapshark == juegoFromApi.idCheapshark)) {
                resultados.add(juegoFromApi);
              }
              _favoriteIds.add(juegoFromApi.idCheapshark);
              continue;
            }

            final raw = await _gestor.fetchRawByGameId(id);
            if (raw != null) {
              final juego = _rawToJuego(raw, id);
              if (!resultados
                  .any((j) => j.idCheapshark == juego.idCheapshark)) {
                resultados.add(juego);
              }
              _favoriteIds.add(juego.idCheapshark);
            } else {
              debugPrint('No raw detail for id=$id');
            }
          } catch (e, st) {
            debugPrint('Error cargando favorito id=$id : $e');
            debugPrint(st.toString());
          }
        }
      }

      if (mounted) {
        setState(() {
          _favoriteGames = resultados;
        });
      } else {
        _favoriteGames = resultados;
      }
    } catch (e, st) {
      debugPrint('Error cargando registros lista desde Firestore: $e');
      debugPrint(st.toString());
      if (mounted) {
        setState(() {
          _favoriteGames = [];
        });
      } else {
        _favoriteGames = [];
      }
    } finally {
      if (mounted) {
        setState(() {});
      } else {}
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

      return Juego(
        idCheapshark: gameId,
        title: nombre.isNotEmpty ? nombre : 'Sin título',
        steamApiID: steamApiID,
        normalPrice: precioBaseRaw,
        steamRatingCount: steamRating, // pendiente
        steamRatingPercent: steamRating,
        metaCriticScore: metaCriticsRating,
        metacriticLink: metacriticLink,
        releaseDate: fechaDeSalida,

        thumb: thumb,
        minimoHistorico: minimoHistorico,
        fechaMinimoHistorico: fechaMin,
        listaPorTienda: <DatoJuegoPorTienda>[],
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
      );
    }
  }

  Future<void> _handleFavoritePressed(
      BuildContext context, Juego juego, bool esFavorito) async {
    final juegoId = juego.idCheapshark.toString();

    if (esFavorito) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("Eliminar favorito",
              style: TextStyle(color: Colors.white)),
          content: Text("¿Quieres eliminar \"${juego.title}\" de favoritos?",
              style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
                child: const Text("Cancelar",
                    style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.pop(context, false)),
            TextButton(
                child: const Text("Eliminar",
                    style: TextStyle(color: Colors.redAccent)),
                onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    final nuevoEstado = !esFavorito;

    setState(() {
      if (nuevoEstado) {
        _favoriteIds.add(juegoId);
        if (!_favoriteGames.any((g) => g.idCheapshark == juegoId)) {
          _favoriteGames.add(juego);
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Añadido a favoritos: ${juego.title}')));
      } else {
        _favoriteIds.remove(juegoId);
        _favoriteGames.removeWhere((g) => g.idCheapshark == juegoId);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eliminado de favoritos: ${juego.title}')));
      }
    });

    final usuario = UsuarioIniciado.usuario;
    if (usuario != null &&
        UsuarioIniciado.sesionIniciada &&
        !UsuarioIniciado.esAnonimo) {
      try {
        final correo = usuario.correo;
        if (nuevoEstado) {
          await _fs.addFavoritoPorCorreo(correo, juegoId);
          await _fs.addListaRegistro(
            idUsuario: UsuarioIniciado.usuarioIdString,
            idJuego: juegoId,
            idSteam: juego.steamApiID.isNotEmpty ? juego.steamApiID : null,
            idCheapshark: juego.idCheapshark.isNotEmpty
                ? juego.idCheapshark
                : juego.idCheapshark,
            title: juego.title,
            thumb: juego.thumb.isNotEmpty ? juego.thumb : null,
          );
        } else {
          await _fs.removeFavoritoPorCorreo(correo, juegoId);
          await _fs.removeListaRegistro(
              idUsuario: UsuarioIniciado.usuarioIdString, idJuego: juegoId);
        }
      } catch (e, st) {
        debugPrint('Error actualizando favoritos en Firestore: $e');
        debugPrint(st.toString());
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Inicia sesión (no anónimo) para guardar favoritos en tu cuenta.')),
        );
      }
    }
  }

  Future<void> _handleTapJuego(Juego juego) async {
    if (_isEnriching) return;

    final gameIdCandidate = (juego.idCheapshark.isNotEmpty)
        ? juego.idCheapshark
        : juego.idCheapshark;
    String gameId = gameIdCandidate;
    if (gameId.isEmpty && juego.idCheapshark.isNotEmpty) {
      gameId = juego.idCheapshark;
    }

    Juego? enriched = juego;

    setState(() {
      _isEnriching = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
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
      } else if (juego.steamApiID.isNotEmpty) {
        final fetched =
            await _gestor.fetchByGameId(juego.steamApiID, useCache: true);
        if (fetched != null) enriched = fetched;
      } else {
        if (juego.title.isNotEmpty) {
          final list = await _gestor.searchByTitle(juego.title, limit: 1);
          if (list.isNotEmpty) enriched = list.first;
        }
      }

      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e, st) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      debugPrint('Error obteniendo detalles al pulsar juego: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isEnriching = false;
        });
      } else {
        _isEnriching = false;
      }
    }

    final toSend = enriched ?? juego;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleJuego(
          title: toSend.title.isNotEmpty ? toSend.title : 'Detalle',
          juego: toSend,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(),
            Expanded(
              child: _currentIndex == 0
                  ? _buildInicioBody()
                  : _currentIndex == 2
                      ? const ListaFavoritos()
                      : Center(child: _getBodyContent()),
            ),
            Container(
              decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _buildNavItem(icon: Icons.home, label: 'Inicio', index: 0),
                    _buildNavItem(
                        icon: Icons.person, label: 'Usuario', index: 1),
                    _buildNavItem(icon: Icons.list, label: 'Listas', index: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInicioBody() {
    return BuscadorWidget(
      favoriteIds: _favoriteIds,
      onFavoritePressed: _handleFavoritePressed,
      onTapJuego: _handleTapJuego,
    );
  }

  Widget _getBodyContent() {
    switch (_currentIndex) {
      case 0:
        return const Text('Página de Inicio',
            style: TextStyle(color: Colors.white, fontSize: 20));
      case 1:
        return const Text('Perfil de Usuario',
            style: TextStyle(color: Colors.white, fontSize: 20));
      case 2:
        return const Text('Tus Listas',
            style: TextStyle(color: Colors.white, fontSize: 20));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final bool selected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: selected ? const Color(0xFFC77DFF) : Colors.white),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: selected ? const Color(0xFFC77DFF) : Colors.white,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
