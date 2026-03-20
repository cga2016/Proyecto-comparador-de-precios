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
    required String title,
  });

  @override
  State<BuscadorWidget> createState() => _BuscadorWidgetState();
}

class _BuscadorWidgetState extends State<BuscadorWidget> {
  final TextEditingController _searchController = TextEditingController();
  final CheapSharkGestor _gestor = CheapSharkGestor();

  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  final TextEditingController _precioMinController = TextEditingController();
  final TextEditingController _precioMaxController = TextEditingController();

  bool _mostrarOpcionesExtra = false;

  Map<String, bool> _tiendasSeleccionadas = {
    for (var id in tiendasReferencia.keys) id: id == "1"
  };

  bool _isSearching = false;
  bool _mostrarFiltros = false;

  double _precioMaximo = 60;
  String _priceMax = "60+";
  double _valoracionMinima = 40;
  bool _soloOfertas = false;
  //double _priceMin = 0;
  String _fechaMin = "";
  String _fechaMax = "";

  DateTime? _selectedFechaMin;
  DateTime? _selectedFechaMax;

  static const Map<String, String> tiendasReferencia = {
    "1": "Steam",
    "7": "GOG",
    "11": "Humble Store",
    "13": "Uplay",
    "25": "Epic Games Store",
  };

  List<String> selectecStores = ["1"];

  //String? _categoriaSeleccionada;

  List<Juego> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _precioMinController.dispose();
    _precioMaxController.dispose();
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
      final resultados = await _gestor.searchByTitle(
        query,
        _precioMaximo.round(),
        _valoracionMinima.round(),
        _soloOfertas,
        false,
        selectecStores,
        limit: 50,
        useCache: false,
      );

      List<Juego> resultadosFiltrados = resultados;
      if (_fechaMin.isNotEmpty || _fechaMax.isNotEmpty) {
        final DateTime? fechaMin =
            _fechaMin.isNotEmpty ? DateTime.parse(_fechaMin) : null;

        final DateTime? fechaMax =
            _fechaMax.isNotEmpty ? DateTime.parse(_fechaMax) : null;

        resultadosFiltrados = resultados.where((juego) {
          if (juego.releaseDate.isEmpty) return false;

          final DateTime fechaJuego = DateTime.parse(juego.releaseDate);

          bool cumple = true;

          if (fechaMin != null) {
            cumple = cumple && !fechaJuego.isBefore(fechaMin);
          }

          if (fechaMax != null) {
            cumple = cumple && !fechaJuego.isAfter(fechaMax);
          }

          return cumple;
        }).toList();
      }

      setState(() => _searchResults = resultadosFiltrados);
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

// comprobar

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
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _mostrarFiltros = !_mostrarFiltros;
                    });
                  },
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _mostrarFiltros
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 350,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _selectFechaMin(context),
                              child: Text(
                                _selectedFechaMin == null
                                    ? "Fecha mínima"
                                    : "${_selectedFechaMin!.day}/${_selectedFechaMin!.month}/${_selectedFechaMin!.year}",
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _selectFechaMax(context),
                              child: Text(
                                _selectedFechaMax == null
                                    ? "Fecha máxima"
                                    : "${_selectedFechaMax!.day}/${_selectedFechaMax!.month}/${_selectedFechaMax!.year}",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          onPressed: _limpiarFechas,
                          child: const Text("Limpiar fechas"),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Rango de precio (€)",
                          style: TextStyle(color: Colors.white)),
                      Slider(
                        value: _precioMaximo,
                        min: 0,
                        max: 60,
                        divisions: 60,
                        label: _precioMaximo == 0
                            ? "0"
                            : _precioMaximo == 60
                                ? "60+ €"
                                : "${_precioMaximo.toStringAsFixed(0)} €",
                        onChanged: (value) {
                          setState(() {
                            _precioMaximo = value;

                            if (value == 0) {
                              _priceMax = "0";
                            } else if (value == 60) {
                              _priceMax = "60+";
                            } else {
                              _priceMax = value.toStringAsFixed(0);
                            }

                            debugPrint("Precio máximo guardado: $_priceMax");
                          });
                        },
                      ),
                      Text(
                        _priceMax.isEmpty
                            ? "Entre 0 € - 0"
                            : _priceMax == "60+"
                                ? "Entre 0 € - 60+ €"
                                : "Entre 0 € - $_priceMax €",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      const Text("Valoraciones mínimas (%)",
                          style: TextStyle(color: Colors.white)),
                      Slider(
                        value: _valoracionMinima,
                        min: 40,
                        max: 95,
                        divisions: 11,
                        label: "${_valoracionMinima.toStringAsFixed(0)} %",
                        onChanged: (value) {
                          setState(() {
                            _valoracionMinima = value;
                          });
                        },
                      ),
                      Text(
                        "Desde ${_valoracionMinima.toStringAsFixed(0)} %",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: _soloOfertas,
                            onChanged: (bool? value) {
                              setState(() {
                                _soloOfertas = value == true;
                              });
                            },
                          ),
                          const Text(
                            "En oferta",
                            style: TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.tune, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _mostrarOpcionesExtra = !_mostrarOpcionesExtra;
                              });
                            },
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _mostrarOpcionesExtra
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: SizedBox(
                          height: 180,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: tiendasReferencia.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 4,
                            ),
                            itemBuilder: (context, index) {
                              final id =
                                  tiendasReferencia.keys.elementAt(index);
                              final nombre = tiendasReferencia[id]!;

                              return CheckboxListTile(
                                dense: true,
                                value: _tiendasSeleccionadas[id],
                                onChanged: (bool? value) {
                                  final seleccionado = value ?? false;

                                  // evitar desmarcar la última tienda
                                  if (!seleccionado &&
                                      selectecStores.length == 1 &&
                                      selectecStores.contains(id)) {
                                    return;
                                  }

                                  setState(() {
                                    _tiendasSeleccionadas[id] = seleccionado;

                                    if (seleccionado) {
                                      if (!selectecStores.contains(id)) {
                                        selectecStores.add(id);
                                      }
                                    } else {
                                      selectecStores.remove(id);
                                    }

                                    debugPrint(
                                        "Tiendas seleccionadas: $selectecStores");
                                  });
                                },
                                title: Text(
                                  nombre,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        Expanded(
          child: _isSearching && _searchResults.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  //   shrinkWrap: true,
                  //   physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final juego = _searchResults[index];
                    final storeId = juego.listaPorTienda.isNotEmpty
                        ? juego.listaPorTienda.first.storeId
                        : juego.storeid;

                    final key = "${juego.idCheapshark}_$storeId";

                    final esFavorito = widget.favoriteIds.contains(key);

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

  Future<void> _selectFechaMin(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime lastAllowed = _selectedFechaMax ?? now;

    final DateTime initial =
        (_selectedFechaMin != null && !_selectedFechaMin!.isAfter(lastAllowed))
            ? _selectedFechaMin!
            : lastAllowed;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: lastAllowed,
    );

    if (picked != null) {
      setState(() {
        _selectedFechaMin = picked;
        _fechaMin = picked.toIso8601String();
      });
    }
  }

  Future<void> _selectFechaMax(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstAllowed = _selectedFechaMin ?? DateTime(2026);

    final DateTime initial = (_selectedFechaMax != null &&
            !_selectedFechaMax!.isBefore(firstAllowed))
        ? _selectedFechaMax!
        : firstAllowed;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedFechaMax = picked;
        _fechaMax = picked.toIso8601String();
      });
    }
  }

  void _limpiarFechas() {
    setState(() {
      _selectedFechaMin = null;
      _selectedFechaMax = null;
      _fechaMin = "";
      _fechaMax = "";
    });
  }
}
