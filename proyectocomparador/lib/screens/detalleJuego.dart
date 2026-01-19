// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/juego.dart';

class DetalleJuego extends StatefulWidget {
  const DetalleJuego({super.key, required this.title, required this.juego});

  final String title;
  final Juego juego;

  @override
  State<DetalleJuego> createState() => _DetalleJuegoState();
}

class _DetalleJuegoState extends State<DetalleJuego> {
  int _bottomIndex = 0;
  late final PageController _carouselController;
  late final List<_CarouselItem> _carouselItems;

  @override
  void initState() {
    super.initState();

    final juego = widget.juego;
    _carouselItems = [];

    if (juego.thumb.isNotEmpty) {
      _carouselItems
          .add(_CarouselItem(type: _CarouselType.image, src: juego.thumb));
    } else if (juego.thumb.isNotEmpty) {
      _carouselItems
          .add(_CarouselItem(type: _CarouselType.image, src: juego.thumb));
    }

    if (_carouselItems.isEmpty) {
      _carouselItems
          .add(_CarouselItem(type: _CarouselType.placeholder, src: ''));
    }

    _carouselController = PageController(viewportFraction: 0.92);

    // Imprimir por consola todos los datos del juego (usa el método que añadiste en Juego)
    try {} catch (e, st) {
      debugPrint('Error llamando a juego.debugPrint(): $e\n$st');
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final juego = widget.juego;
    return Scaffold(
      backgroundColor: const Color(0xFF7B2CBF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A189A),
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Imprimir datos en consola',
            icon: const Icon(Icons.print),
            onPressed: () {
              try {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Datos del juego impresos en consola')),
                  );
                }
              } catch (e) {
                debugPrint('Error imprimiendo juego.debugPrint(): $e');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _bottomIndex == 0
                  ? _buildDetalleTab(context, juego)
                  : _buildComparadorTab(context, juego),
            ),
            Container(
              decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  backgroundColor: const Color(0xFF1A1A1A),
                  selectedItemColor: const Color(0xFFC77DFF),
                  unselectedItemColor: Colors.white,
                  currentIndex: _bottomIndex,
                  onTap: (i) => setState(() => _bottomIndex = i),
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.info), label: 'Detalle'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.compare_arrows), label: 'Comparador'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleTab(BuildContext context, Juego juego) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            juego.title.isNotEmpty
                ? juego.title
                : (juego.title.isNotEmpty ? juego.title : 'Sin título'),
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _carouselController,
              itemCount: _carouselItems.length,
              itemBuilder: (context, index) {
                final item = _carouselItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildCarouselCard(context, item),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_carouselItems.length > 1)
            Center(
              child: Text(
                '${_carouselItems.length} elementos multimedia',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          _buildMetaRow(
              'Precio actual',
              _formatPriceFromStringOrDouble(
                  juego.normalPrice, juego.minimoHistorico)),
          _buildMetaRow(
              'Mínimo histórico', _formatPriceDouble(juego.minimoHistorico)),
          _buildMetaRow('Steam ID',
              juego.steamApiID.isNotEmpty ? juego.steamApiID : 'No disponible'),
          const SizedBox(height: 12),
          _buildSectionTitle('Descripción'),
          const SizedBox(height: 16),
          const SizedBox(height: 20),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildComparadorTab(BuildContext context, Juego juego) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows, size: 48, color: Colors.white54),
          SizedBox(height: 12),
          Text('', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(BuildContext context, _CarouselItem item) {
    switch (item.type) {
      case _CarouselType.image:
        return Card(
          color: const Color(0xFF2A2A2A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.src,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(
                color: Colors.grey[800],
                child: const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white, size: 36)),
              ),
            ),
          ),
        );

      case _CarouselType.video:
        return Card(
          color: const Color(0xFF2A2A2A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showVideoDialog(context, item.src),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill,
                      size: 56, color: Colors.white70),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Vídeo\n${_shorten(item.src, 60)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        );

      case _CarouselType.placeholder:
      default:
        return Card(
          color: const Color(0xFF2A2A2A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            alignment: Alignment.center,
            child: const Icon(Icons.videogame_asset,
                color: Colors.white54, size: 56),
          ),
        );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(title,
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  void _showVideoDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Vídeo', style: TextStyle(color: Colors.white)),
        content:
            SelectableText(url, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar',
                  style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  String _shorten(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }

  String _formatPriceDouble(double price) {
    try {
      if (price.isNaN) return '-';
      if (price <= 0) return 'Gratis';
      return price.toStringAsFixed(2);
    } catch (_) {
      return '-';
    }
  }

  String _formatPriceFromStringOrDouble(
      String precioBaseAsString, double minimoHistorico) {
    final parsed = _tryParseDouble(precioBaseAsString);
    if (parsed != null) {
      if (parsed <= 0) return 'Gratis';
      return parsed.toStringAsFixed(2);
    }
    if (minimoHistorico > 0) return minimoHistorico.toStringAsFixed(2);
    return 'No disponible';
  }

  double? _tryParseDouble(String? s) {
    if (s == null) return null;
    final clean = s.replaceAll(',', '.').trim();
    try {
      return double.parse(clean);
    } catch (_) {
      return null;
    }
  }
}

enum _CarouselType { image, video, placeholder }

class _CarouselItem {
  final _CarouselType type;
  final String src;
  _CarouselItem({required this.type, required this.src});
}
