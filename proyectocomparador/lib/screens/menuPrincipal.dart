// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/juego.dart';

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
  bool _isSearching = false;

  List<Juego> _searchResults = [];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gestor.dispose();
    super.dispose();
  }

  Future<void> _performSearchAndPrintJson() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      debugPrint('[MenuPrincipal] Campo de búsqueda vacío.');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      debugPrint('[MenuPrincipal] Buscando "$query" en CheapShark...');

      final rawSearch = await _gestor.searchByName(query, limit: 20);
      debugPrint('[MenuPrincipal] rawSearch length = ${rawSearch.length}');

      if (rawSearch.isEmpty) {
        debugPrint(
            '[MenuPrincipal] No se encontraron coincidencias para "$query".');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('No se encontraron coincidencias para "$query".')),
          );
        }
        setState(() => _isSearching = false);
        return;
      }

      final prettySearch =
          const JsonEncoder.withIndent('  ').convert(rawSearch);
      debugPrint('--- JSON: resultados de búsqueda ---\n$prettySearch');

      final mapped = await _gestor.searchByTitle(query, limit: 20);

      setState(() {
        _searchResults = mapped;
      });

      final first = rawSearch.first;
      final firstGameId = first['gameID']?.toString() ?? '';
      if (firstGameId.isNotEmpty) {
        final rawDetail = await _gestor.fetchRawByGameId(firstGameId);
        if (rawDetail != null) {
          final prettyDetail =
              const JsonEncoder.withIndent('  ').convert(rawDetail);
          debugPrint(
              '--- JSON: detalle del juego (gameID=$firstGameId) ---\n$prettyDetail');
        } else {
          debugPrint(
              '[MenuPrincipal] No se pudo obtener detalle para gameID=$firstGameId');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Encontrados ${mapped.length} resultados. Desplázate para verlos.')),
        );
      }
    } catch (e, st) {
      debugPrint('[MenuPrincipal] Error al buscar: $e');
      debugPrint(st.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error en la búsqueda. Revisa la consola (F12) para más detalles.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      } else {
        _isSearching = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex != 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
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
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (_) =>
                                    _performSearchAndPrintJson(),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Buscar',
                              onPressed: _isSearching
                                  ? null
                                  : _performSearchAndPrintJson,
                              icon: _isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.search,
                                      color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _currentIndex == 0
                  ? _buildInicioBody()
                  : Center(child: _getBodyContent()),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
              ),
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
    if (_isSearching && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final juego = _searchResults[index];
            return _buildJuegoTile(juego);
          },
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildJuegoTile(Juego juego) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2A2A2A),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Seleccionado: ${juego.titulo}')));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 54,
                  child: juego.urlImagenPequena.isNotEmpty
                      ? Image.network(
                          juego.urlImagenPequena,
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
                      juego.titulo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Precio: ${_formatPrice(juego.precioActual)}',
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
                    'Min: ${_formatPrice(juego.precioMinimo)}',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price <= 0) return 'Gratis';
    return price.toStringAsFixed(2);
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

  // ignore: unused_element
  Widget _buildBoton({
    required String texto,
    required String ruta,
    String tooltip = '',
    bool enabled = true,
  }) {
    return FloatingActionButton.extended(
      label: Text(texto,
          style: const TextStyle(fontSize: 25.20, color: Colors.white)),
      backgroundColor: enabled ? const Color(0xFFC77DFF) : Colors.grey,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
      onPressed: enabled
          ? () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ruta);
            }
          : null,
      tooltip: tooltip,
    );
  }
}
