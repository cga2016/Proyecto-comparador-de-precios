import 'package:flutter/material.dart';
import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';

class NotificacionesOpciones extends StatefulWidget {
  const NotificacionesOpciones({super.key});

  @override
  State<NotificacionesOpciones> createState() => _NotificacionesOpcionesState();
}

class _NotificacionesOpcionesState extends State<NotificacionesOpciones> {
  final FirestoreService _fs = FirestoreService();

  bool apagarNotificaciones = false;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _juegosFavoritos = [];
  List<Map<String, dynamic>> _juegosFiltrados = [];

  Map<String, dynamic>? _juegoSeleccionado;

  int? _tipoNotificacion;

  String? _valorNotificacion;
  double _precioDeseado = 0;
  final CheapSharkGestor _cheapShark = CheapSharkGestor();

  double _precioMaximo = 100;
  bool _cargandoPrecio = false;
  int _pasoSlider = 0;

  bool _buscando = false;

  static const Map<String, String> iconosTiendas = {
    "1": "https://www.cheapshark.com/img/stores/icons/0.png",
    "7": "https://www.cheapshark.com/img/stores/icons/6.png",
    "11": "https://www.cheapshark.com/img/stores/icons/10.png",
    "13": "https://www.cheapshark.com/img/stores/icons/12.png",
    "25": "https://www.cheapshark.com/img/stores/icons/24.png",
  };

  @override
  void initState() {
    super.initState();
    _cargarFavoritosUsuario();
    _cargarEstadoNotificaciones();
  }

  Future<void> _cargarFavoritosUsuario() async {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) return;

    try {
      final registros = await _fs
          .obtenerRegistrosListaPorUsuario(UsuarioIniciado.usuarioIdString);

      setState(() {
        _juegosFavoritos = registros;
      });
    } catch (e) {
      debugPrint("Error cargando favoritos: $e");
    }
  }

  void _filtrarJuegos(String texto) {
    final query = texto.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _buscando = false;
        _juegosFiltrados.clear();
      });
      return;
    }

    final resultados = _juegosFavoritos.where((juego) {
      final titulo = (juego['title'] ?? '').toString().toLowerCase();
      return titulo.contains(query);
    }).toList();

    setState(() {
      _juegosFiltrados = resultados;
      _buscando = resultados.isNotEmpty;
    });
  }

  void _limpiarBuscador() {
    _searchController.clear();
    setState(() {
      _buscando = false;
      _juegosFiltrados.clear();
    });
  }

  void _seleccionarJuego(Map<String, dynamic> juego) {
    setState(() {
      _juegoSeleccionado = juego;

      _tipoNotificacion = null;
      _valorNotificacion = null;

      _searchController.clear();
      _buscando = false;
      _juegosFiltrados.clear();
    });
  }

  Widget _buildJuegoTile(Map<String, dynamic> juego) {
    final thumb = juego['thumb'] ?? '';
    final title = juego['title'] ?? '';
    final idTienda = juego['idTienda'] ?? '';
    final iconoTienda = iconosTiendas[idTienda] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF240046),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              thumb,
              width: 80,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          if (iconoTienda.isNotEmpty)
            Image.network(
              iconoTienda,
              width: 26,
              height: 26,
            ),
        ],
      ),
    );
  }

  Future<void> _cargarPrecioJuego() async {
    if (_juegoSeleccionado == null) return;

    final idCheap = _juegoSeleccionado!['idCheapshark'];
    final idTienda = _juegoSeleccionado!['idTienda'];

    setState(() {
      _cargandoPrecio = true;
    });

    try {
      final tiendas = await _cheapShark.fetchDealsByCheapSharkId(idCheap);

      final tienda = tiendas.firstWhere(
        (t) => t.storeId == idTienda,
        orElse: () => tiendas.first,
      );

      final precioBase = tienda.retailPrice;
      setState(() {
        final base = precioBase > 0 ? precioBase : 60;

        double inicio = base - 0.5;
        if (inicio < 0) inicio = 0;

        _precioMaximo = (inicio * 2).floor() / 2;

        _pasoSlider = (_precioMaximo * 2).round();

        _precioDeseado = _pasoSlider / 2;

        _cargandoPrecio = false;
      });
    } catch (e) {
      debugPrint("Error obteniendo precio: $e");

      setState(() {
        _precioMaximo = 60;
        _precioDeseado = 60;
        _cargandoPrecio = false;
      });
    }
  }

  Future<void> _cargarEstadoNotificaciones() async {
    try {
      final estado = await _fs
          .obtenerEstadoNotificaciones(UsuarioIniciado.usuarioIdString);

      setState(() {
        apagarNotificaciones = estado;
      });
    } catch (e) {
      debugPrint("Error cargando estado notificaciones: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioIniciado.usuario;

    if (usuario == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF5A189A),
        body: Center(
          child: Text(
            "No hay sesión iniciada",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF5A189A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C096C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notificaciones",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Configuración de notificaciones",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                constraints: BoxConstraints(
                  maxHeight:
                      (_buscando && _juegosFiltrados.isNotEmpty) ? 350 : 90,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10002B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: _filtrarJuegos,
                            decoration: InputDecoration(
                              hintText: "Buscar juego...",
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF240046),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.white70),
                            onPressed: _limpiarBuscador,
                          ),
                      ],
                    ),
                    if (_buscando && _juegosFiltrados.isNotEmpty)
                      const SizedBox(height: 12),
                    if (_buscando && _juegosFiltrados.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _juegosFiltrados.length,
                          itemBuilder: (context, index) {
                            final juego = _juegosFiltrados[index];

                            return GestureDetector(
                              onTap: () => _seleccionarJuego(juego),
                              child: _buildJuegoTile(juego),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_juegoSeleccionado != null) ...[
                const Text(
                  "Juego seleccionado",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildJuegoTile(_juegoSeleccionado!),
                const SizedBox(height: 20),
              ],
              RadioListTile(
                value: 1,
                groupValue: _tipoNotificacion,
                onChanged: _juegoSeleccionado == null
                    ? null
                    : (value) {
                        setState(() {
                          _tipoNotificacion = value as int;
                          _valorNotificacion = "0";
                        });
                      },
                title: const Text(
                  "Notificar si oferta",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              RadioListTile(
                value: 2,
                groupValue: _tipoNotificacion,
                onChanged: _juegoSeleccionado == null
                    ? null
                    : (value) {
                        setState(() {
                          _tipoNotificacion = value as int;
                          _valorNotificacion = "1";
                          _cargarPrecioJuego();
                        });
                      },
                title: const Text(
                  "Notificar si precio deseado",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              RadioListTile(
                value: 3,
                groupValue: _tipoNotificacion,
                onChanged: _juegoSeleccionado == null
                    ? null
                    : (value) {
                        setState(() {
                          _tipoNotificacion = value as int;
                          _valorNotificacion = "borrar";
                        });
                      },
                title: const Text(
                  "Borrar notificación del juego",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
              if (_valorNotificacion == "1") ...[
                const SizedBox(height: 10),
                if (_cargandoPrecio)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else ...[
                  Text(
                    "Precio deseado: ${_precioDeseado.toStringAsFixed(2)}€",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Porcentaje esperado: ${(((_precioMaximo + 0.5 - _precioDeseado) / (_precioMaximo + 0.5)) * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Slider(
                    value: _pasoSlider.toDouble(),
                    min: 0,
                    max: (_precioMaximo * 2),
                    divisions: (_precioMaximo * 2).round(),
                    label: (_pasoSlider / 2).toStringAsFixed(2),
                    activeColor: const Color(0xFFC77DFF),
                    onChanged: (value) {
                      setState(() {
                        _pasoSlider = value.round();
                        _precioDeseado = _pasoSlider / 2;
                      });
                    },
                  )
                ],
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_juegoSeleccionado == null ||
                        _tipoNotificacion == null) {
                      return;
                    }

                    try {
                      if (_tipoNotificacion == 3) {
                        await _fs.borrarNotificacion(
                          idUser: UsuarioIniciado.usuarioIdString,
                          idCheapshark:
                              _juegoSeleccionado!['idCheapshark']?.toString() ??
                                  "",
                          idTienda:
                              _juegoSeleccionado!['idTienda']?.toString() ?? "",
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Notificación eliminada"),
                            ),
                          );
                        }

                        return;
                      }

                      String precio = "";
                      String porcentaje = "";
                      if (_tipoNotificacion == 2) {
                        precio = _precioDeseado.toStringAsFixed(2);

                        porcentaje = (((_precioMaximo + 0.5 - _precioDeseado) /
                                    (_precioMaximo + 0.5)) *
                                100)
                            .toStringAsFixed(0);
                      }

                      await _fs.guardarNotificacion(
                        idUser: UsuarioIniciado.usuarioIdString,
                        idCheapshark:
                            _juegoSeleccionado!['idCheapshark']?.toString() ??
                                "",
                        idSteam:
                            _juegoSeleccionado!['idSteam']?.toString() ?? "",
                        idTienda:
                            _juegoSeleccionado!['idTienda']?.toString() ?? "",
                        titulo: _juegoSeleccionado!['title']?.toString() ?? "",
                        porcentajeDescuento: porcentaje,
                        precioDeseado: precio,
                        tipoNotificacion: _tipoNotificacion == 1 ? "0" : "1",
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Notificación guardada correctamente"),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error guardando notificación: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Guardar",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: apagarNotificaciones,
                onChanged: (_) async {
                  try {
                    final nuevoEstado = await _fs.toggleEstadoNotificaciones(
                      UsuarioIniciado.usuarioIdString,
                    );

                    setState(() {
                      apagarNotificaciones = nuevoEstado;
                    });
                  } catch (e) {
                    debugPrint("Error cambiando estado: $e");
                  }
                },
                activeColor: const Color(0xFFC77DFF),
                title: const Text(
                  "Desactivar notificaciones",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
