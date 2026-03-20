import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/dataJuego.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';
import 'package:proyectocomparador/screens/detalleJuego.dart';

class MostrarNotificaciones extends StatefulWidget {
  const MostrarNotificaciones({super.key});

  @override
  State<MostrarNotificaciones> createState() => _MostrarNotificacionesState();
}

class _MostrarNotificacionesState extends State<MostrarNotificaciones> {
  final FirestoreService _fs = FirestoreService();
  final CheapSharkGestor _cheap = CheapSharkGestor();

  Map<String, Map<String, dynamic>> _infoPrecios = {};

  List<Map<String, dynamic>> _notificaciones = [];
  bool _loading = true;
  bool _isEnriching = false;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<Map<String, dynamic>> _cumpleCondicionConDatos(
      Map<String, dynamic> n) async {
    final tipo = n["TipoNotificacion"] ?? "0";
    final idCheap = n["IdCheapshark"] ?? "";

    if (idCheap.isEmpty) return {"cumple": false};

    try {
      final deals = await _cheap.fetchDealsByCheapSharkId(idCheap);

      if (deals.isEmpty) return {"cumple": false};

      final mejorDeal = deals.reduce(
        (a, b) => a.price < b.price ? a : b,
      );

      final precio = mejorDeal.price;
      final precioBase = mejorDeal.retailPrice;

      final data = {
        "precio": precio,
        "precioBase": precioBase,
        "descuento":
            precioBase > 0 ? ((1 - (precio / precioBase)) * 100).round() : 0,
      };

      if (tipo == "0") {
        return {
          "cumple": precio < precioBase,
          "data": data,
        };
      } else {
        final precioDeseado =
            double.tryParse(n["precioDeseado"]?.toString() ?? "") ?? 0.0;

        return {
          "cumple": precio <= precioDeseado,
          "data": data,
        };
      }
    } catch (e) {
      debugPrint("Error comprobando condición: $e");
      return {"cumple": false};
    }
  }

  Future<void> _cargarNotificaciones() async {
    final usuario = UsuarioIniciado.usuario;

    if (usuario == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final lista = await _fs
          .obtenerNotificacionesUsuario(UsuarioIniciado.usuarioIdString);

      List<Map<String, dynamic>> filtradas = [];
      Map<String, Map<String, dynamic>> nuevosPrecios = {};

      for (final n in lista) {
        final result = await _cumpleCondicionConDatos(n);

        if (result["cumple"]) {
          filtradas.add(n);
          nuevosPrecios[n["IdCheapshark"]] = result["data"];
        }
      }

      setState(() {
        _notificaciones = filtradas;
        _infoPrecios = nuevosPrecios;
      });
    } catch (e) {
      debugPrint("Error cargando notificaciones: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _eliminarNotificacion(Map<String, dynamic> n) async {
    final idUser = UsuarioIniciado.usuarioIdString;
    final idCheap = n["IdCheapshark"] ?? "";
    final idTienda = n["idTienda"] ?? "";

    await _fs.borrarNotificacion(
      idUser: idUser,
      idCheapshark: idCheap,
      idTienda: idTienda,
    );

    _cargarNotificaciones();
  }

  String _getImagenJuego(Map<String, dynamic> n) {
    final steamId = n["IdSteam"] ?? "";

    if (steamId.isNotEmpty) {
      return "https://cdn.cloudflare.steamstatic.com/steam/apps/$steamId/capsule_sm_120.jpg";
    }

    return "https://via.placeholder.com/120x45.png?text=Juego";
  }

  Widget _buildPrecioWidget(Map<String, dynamic> n) {
    final idCheap = n["IdCheapshark"] ?? "";

    if (!_infoPrecios.containsKey(idCheap)) {
      return const SizedBox();
    }

    final data = _infoPrecios[idCheap];
    final precio = data?["precio"];
    final precioBase = data?["precioBase"];
    final descuento = data?["descuento"];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 💰 Precio actual
        Text(
          "${precio.toStringAsFixed(2)}€",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),

        // 🏷️ Precio original tachado
        if (precioBase != null && precioBase > precio)
          Text(
            "${precioBase.toStringAsFixed(2)}€",
            style: const TextStyle(
              color: Colors.white54,
              decoration: TextDecoration.lineThrough,
            ),
          ),

        // 🎯 Descuento
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE0AAFF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "-$descuento%",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTapJuego(Map<String, dynamic> n) async {
    if (_isEnriching) return;

    final idCheap = n["IdCheapshark"] ?? "";
    final titulo = n["Titulo"] ?? "Juego";
    final steamId = n["IdSteam"] ?? "";

    if (idCheap.isEmpty) return;

    setState(() {
      _isEnriching = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 🔹 1. Obtener juego completo
      Juego? juego = await _cheap.fetchByGameId(idCheap, useCache: true);

      if (juego == null) {
        final raw = await _cheap.fetchRawByGameId(idCheap);
        if (raw != null) {
          juego = _rawToJuego(raw, idCheap);
        }
      }

      // 🔹 2. Tiendas
      List<DatoJuegoPorTienda> tiendas = [];
      tiendas = await _cheap.fetchDealsByCheapSharkId(idCheap);

      // 🔹 3. Steam
      DataJuego? steamData;
      if (steamId.isNotEmpty) {
        steamData = await _cheap.fetchSteamGameData(
          steamId,
          useCache: true,
        );
      }

      if (Navigator.canPop(context)) Navigator.pop(context);

      final juegoFinal = juego ??
          Juego(
            idCheapshark: idCheap,
            title: titulo,
            steamApiID: steamId,
            normalPrice: '0',
            steamRatingCount: '',
            steamRatingPercent: '',
            metaCriticScore: '',
            metacriticLink: '',
            releaseDate: '',
            thumb: _getImagenJuego(n),
            minimoHistorico: 0,
            fechaMinimoHistorico: '',
            listaPorTienda: tiendas,
            storeid: '',
          );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleJuego(
            title: juegoFinal.title,
            juego: juegoFinal,
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

      return Juego(
        idCheapshark: gameId,
        title: (info['title'] ?? '').toString(),
        steamApiID: (info['steamAppID'] ?? '').toString(),
        normalPrice: (raw['cheapest'] ?? '0').toString(),
        steamRatingCount: '',
        steamRatingPercent: '',
        metaCriticScore: '',
        metacriticLink: '',
        releaseDate: '',
        thumb: (info['thumb'] ?? '').toString(),
        minimoHistorico: 0,
        fechaMinimoHistorico: '',
        listaPorTienda: [],
        storeid: '',
      );
    } catch (_) {
      return Juego(
        idCheapshark: gameId,
        title: 'Juego',
        steamApiID: '',
        normalPrice: '0',
        steamRatingCount: '',
        steamRatingPercent: '',
        metaCriticScore: '',
        metacriticLink: '',
        releaseDate: '',
        thumb: '',
        minimoHistorico: 0,
        fechaMinimoHistorico: '',
        listaPorTienda: [],
        storeid: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C096C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notificaciones",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? const Center(
                  child: Text(
                    "No tienes notificaciones",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _notificaciones.length,
                  itemBuilder: (context, index) {
                    final n = _notificaciones[index];

                    return GestureDetector(
                      onTap: () => _handleTapJuego(n),
                      child: Card(
                        color: const Color(0xFF1A1A1A),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 8,
                            right: 4, // 👈 menos espacio a la derecha
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              _getImagenJuego(n),
                              width: 70,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            n["Titulo"] ?? "Juego",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildPrecioWidget(n),
                          trailing: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => _eliminarNotificacion(n),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
