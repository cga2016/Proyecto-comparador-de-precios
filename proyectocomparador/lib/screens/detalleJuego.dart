// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'package:proyectocomparador/firebase/firebase.dart';
import 'package:proyectocomparador/gestor/cheapSharkGestor.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/dataJuego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';
import 'package:proyectocomparador/models/usuarioIniciado.dart';
import 'package:proyectocomparador/screens/comparadorTab.dart';
import 'package:proyectocomparador/widgets/videoPlayerWidget.dart';

class DetalleJuego extends StatefulWidget {
  const DetalleJuego({
    super.key,
    required this.title,
    required this.juego,
    this.steamData,
  });

  final String title;
  final Juego juego;
  final DataJuego? steamData;

  @override
  State<DetalleJuego> createState() => _DetalleJuegoState();
}

class _DetalleJuegoState extends State<DetalleJuego> {
  int _bottomIndex = 0;
  late final PageController _carouselController;
  late final List<_CarouselItem> _carouselItems;
  double _carouselPosition = 0;
  final CheapSharkGestor _gestor = CheapSharkGestor();
  final FirestoreService _fs = FirestoreService();

  bool _mostrarNotificaciones = false;

  int? _tipoNotificacion;
  double _precioDeseado = 10;
  double _precioMaximo = 100;
  bool _cargandoPrecioNotif = false;
  int _pasoSliderNotif = 0;

  bool _esFavorito = false;
  bool _cargandoFavorito = true;

  List<DatoJuegoPorTienda> _tiendas = [];

  bool _loadingTiendas = false;

  @override
  void initState() {
    super.initState();
    _cargarEstadoFavorito();

    _carouselItems = [];

    final steam = widget.steamData;

    if (steam != null) {
      // Añadir vídeos
      for (final video in steam.movies) {
        _carouselItems.add(
          _CarouselItem(
            type: _CarouselType.video,
            src: video["video"]!,
            thumbnail: video["thumbnail"],
          ),
        );
      }

      for (final img in steam.screenshots) {
        _carouselItems.add(
          _CarouselItem(type: _CarouselType.image, src: img),
        );
      }

      // 🔥 Imprimir todo por consola
      debugPrint("===== STEAM DATA EN DETALLE =====");
      debugPrint("Nombre: ${steam.name}");
      debugPrint("Fecha: ${steam.date}");
      debugPrint("Descripción: ${steam.descripcion}");
      debugPrint("Screenshots: ${steam.screenshots}");
      debugPrint("Movies: ${steam.movies}");
      debugPrint("Req Min: ${steam.requisitosMinimos}");
      debugPrint("Req Rec: ${steam.requisitosRecomendados}");
      debugPrint("==================================");
    }

    if (_carouselItems.isEmpty && widget.juego.thumb.isNotEmpty) {
      _carouselItems.add(
        _CarouselItem(type: _CarouselType.image, src: widget.juego.thumb),
      );
    }

    if (_carouselItems.isEmpty) {
      _carouselItems.add(
        _CarouselItem(type: _CarouselType.placeholder, src: ''),
      );
    }

    _carouselController = PageController(viewportFraction: 0.92);

    _carouselController.addListener(() {
      final page = _carouselController.page ?? 0;
      if ((page - _carouselPosition).abs() > 0.01) {
        setState(() {
          _carouselPosition = page;
        });
      }
    });
    _cargarTiendas();
  }

  Future<void> _cargarEstadoFavorito() async {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) {
      setState(() => _cargandoFavorito = false);
      return;
    }

    try {
      final favoritos = await _fs.obtenerFavoritosPorCorreo(usuario.correo);

      setState(() {
        _esFavorito = favoritos.contains(widget.juego.idCheapshark);
      });
    } catch (e) {
      debugPrint("Error comprobando favorito: $e");
    } finally {
      setState(() => _cargandoFavorito = false);
    }
  }

  Future<void> _toggleFavorito() async {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null) return;

    final correo = usuario.correo;
    final idJuego = widget.juego.idCheapshark;

    if (_esFavorito) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar favorito'),
          content: Text(
              '¿Eliminar "${widget.juego.title}" de la lista de deseados?'),
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

    setState(() {
      _esFavorito = !_esFavorito;
    });

    try {
      if (_esFavorito) {
        await _fs.addFavoritoPorCorreo(correo, idJuego);

        await _fs.addListaRegistro(
          idUsuario: UsuarioIniciado.usuarioIdString,
          idJuego: idJuego,
          idSteam: widget.juego.steamApiID,
          idCheapshark: widget.juego.idCheapshark,
          idTienda: widget.juego.storeid,
          title: widget.juego.title,
          thumb: widget.juego.thumb,
        );
      } else {
        await _fs.removeListaRegistro(
          idUsuario: UsuarioIniciado.usuarioIdString,
          idJuego: idJuego,
          idTienda: widget.juego.storeid,
        );

        await _fs.removeFavoritoPorCorreo(correo, idJuego);

        await _fs.borrarNotificacion(
          idUser: UsuarioIniciado.usuarioIdString,
          idCheapshark: widget.juego.idCheapshark,
          idTienda: widget.juego.storeid,
        );

        await _fs.removeFavoritoPorCorreo(correo, idJuego);
      }
    } catch (e) {
      debugPrint("Error actualizando favorito: $e");
    }
  }

  Future<void> _cargarPrecioNotificacion() async {
    try {
      final tiendas = await _gestor.fetchDealsByCheapSharkId(
        widget.juego.idCheapshark,
      );

      final tienda = tiendas.first;

      final base = tienda.retailPrice > 0 ? tienda.retailPrice : 60;

      double inicio = base - 0.5;
      if (inicio < 0) inicio = 0;

      setState(() {
        _precioMaximo = (inicio * 2).floor() / 2;
        _pasoSliderNotif = (_precioMaximo * 2).round();
        _precioDeseado = _pasoSliderNotif / 2;
        _cargandoPrecioNotif = false;
      });
    } catch (e) {
      debugPrint("Error precio notif: $e");

      setState(() {
        _precioMaximo = 60;
        _precioDeseado = 60;
        _cargandoPrecioNotif = false;
      });
    }
  }

  Future<void> _guardarNotificacion() async {
    final usuario = UsuarioIniciado.usuario;
    if (usuario == null || _tipoNotificacion == null) return;

    try {
      if (_tipoNotificacion == 3) {
        await _fs.borrarNotificacion(
          idUser: UsuarioIniciado.usuarioIdString,
          idCheapshark: widget.juego.idCheapshark,
          idTienda: widget.juego.storeid,
        );
      } else {
        String precio = "";
        String porcentaje = "";

        if (_tipoNotificacion == 2) {
          precio = _precioDeseado.toStringAsFixed(2);

          porcentaje =
              (((_precioMaximo - _precioDeseado) / _precioMaximo) * 100)
                  .toStringAsFixed(0);
        }

        await _fs.guardarNotificacion(
          idUser: UsuarioIniciado.usuarioIdString,
          idCheapshark: widget.juego.idCheapshark,
          idSteam: widget.juego.steamApiID,
          idTienda: widget.juego.storeid,
          titulo: widget.juego.title,
          porcentajeDescuento: porcentaje,
          precioDeseado: precio,
          tipoNotificacion: _tipoNotificacion == 1 ? "0" : "1",
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guardado correctamente")),
      );
    } catch (e) {
      debugPrint("Error guardando notificación: $e");
    }
  }

  Future<void> _cargarTiendas() async {
    final id = widget.juego.idCheapshark;

    if (id.isEmpty) return;

    setState(() {
      _loadingTiendas = true;
    });

    try {
      final lista = await _gestor.fetchDealsByCheapSharkId(id);

      if (mounted) {
        setState(() {
          _tiendas = lista;
        });
      }
    } catch (e) {
      debugPrint("Error cargando tiendas: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingTiendas = false;
        });
      }
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
      backgroundColor: const Color(0xFF5A189A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C096C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_cargandoFavorito)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                setState(() {
                  _mostrarNotificaciones = !_mostrarNotificaciones;
                });
              },
            ),
          IconButton(
            icon: Icon(
              _esFavorito ? Icons.star : Icons.star_border,
              color: _esFavorito ? Colors.amber : Colors.white,
              size: 30,
            ),
            onPressed: _toggleFavorito,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _mostrarNotificaciones ? null : 0,
              curve: Curves.easeInOut,
              child: _mostrarNotificaciones
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF3C096C),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Notificaciones",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          /// RADIO BUTTONS
                          RadioListTile(
                            value: 1,
                            groupValue: _tipoNotificacion,
                            onChanged: (value) {
                              setState(() {
                                _tipoNotificacion = value as int;
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
                            onChanged: (value) async {
                              setState(() {
                                _tipoNotificacion = value as int;
                                _cargandoPrecioNotif = true;
                              });

                              await _cargarPrecioNotificacion();
                            },
                            title: const Text(
                              "Notificar si precio deseado",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          RadioListTile(
                            value: 3,
                            groupValue: _tipoNotificacion,
                            onChanged: (value) {
                              setState(() {
                                _tipoNotificacion = value as int;
                              });
                            },
                            title: const Text(
                              "Borrar notificación",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          /// SLIDER SOLO SI PRECIO
                          if (_tipoNotificacion == 2) ...[
                            const SizedBox(height: 10),
                            if (_cargandoPrecioNotif)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              Text(
                                "Precio: ${_precioDeseado.toStringAsFixed(2)}€",
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                "Descuento: ${(((_precioMaximo - _precioDeseado) / _precioMaximo) * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Slider(
                                value: _pasoSliderNotif.toDouble(),
                                min: 0,
                                max: (_precioMaximo * 2),
                                divisions: (_precioMaximo * 2).round(),
                                activeColor: const Color(0xFFC77DFF),
                                onChanged: (value) {
                                  setState(() {
                                    _pasoSliderNotif = value.round();
                                    _precioDeseado = _pasoSliderNotif / 2;
                                  });
                                },
                              ),
                            ],
                          ],

                          const SizedBox(height: 10),

                          /// BOTÓN GUARDAR
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _guardarNotificacion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B2CBF),
                              ),
                              child: const Text("Guardar",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: const Color(0xFF10002B),
            child: Text(
              juego.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF10002B),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                /// CAROUSEL
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _carouselController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _carouselItems.length,
                    itemBuilder: (context, index) {
                      final item = _carouselItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildCarouselCard(context, item),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                /// SLIDER
                if (_carouselItems.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: _carouselPosition.clamp(
                          0,
                          (_carouselItems.length - 1).toDouble(),
                        ),
                        min: 0,
                        max: (_carouselItems.length - 1).toDouble(),
                        divisions: _carouselItems.length - 1,
                        activeColor: const Color(0xFFC77DFF),
                        inactiveColor: Colors.white24,
                        onChanged: (value) {
                          _carouselController.animateToPage(
                            value.round(),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.steamData?.genres != null &&
              widget.steamData!.genres.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10002B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Géneros: ",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        widget.steamData!.genres.join(", "),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10002B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow(
                  'Desarrollador',
                  widget.steamData?.developers ?? "No disponible",
                ),
                _buildMetaRow(
                  'Publisher',
                  widget.steamData?.publisher ?? "No disponible",
                ),
                _buildMetaRow(
                  'Recomendaciones',
                  widget.steamData?.recommendations ?? "No disponible",
                ),
                if (widget.steamData?.requiredAge != null &&
                    widget.steamData!.requiredAge != "0")
                  _buildMetaRow(
                    'Edad requerida',
                    widget.steamData!.requiredAge,
                  ),
                _buildMetaRow(
                  'Fecha lanzamiento',
                  widget.steamData?.date ?? "No disponible",
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10002B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Descripción',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.steamData?.descripcion.map((item) {
                      if (item.startsWith('http')) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Image.network(
                            item,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              color: Colors.grey[800],
                              height: 200,
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.white, size: 36),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            item,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                    }).toList() ??
                    [
                      const Text(
                        "No disponible",
                        style: TextStyle(color: Colors.white70),
                      )
                    ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildComparadorTab(BuildContext context, Juego juego) {
    return ComparadorTab(
      juego: juego,
      tiendas: _tiendas,
      loading: _loadingTiendas,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showVideoDialog(context, item.src),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.thumbnail != null && item.thumbnail!.isNotEmpty)
                    Image.network(
                      item.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        color: Colors.grey[800],
                      ),
                    )
                  else
                    Container(color: Colors.grey[800]),
                  Container(
                    color: Colors.black45,
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case _CarouselType.placeholder:
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
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: VideoPlayerWidget(url: url),
      ),
    );
  }
}

enum _CarouselType { image, video, placeholder }

class _CarouselItem {
  final _CarouselType type;
  final String src;
  final String? thumbnail;

  _CarouselItem({
    required this.type,
    required this.src,
    this.thumbnail,
  });
}
