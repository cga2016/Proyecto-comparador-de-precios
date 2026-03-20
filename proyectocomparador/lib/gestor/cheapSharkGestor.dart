// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:proyectocomparador/models/dataJuego.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';

class CheapSharkGestor {
  static const String _base = 'https://www.cheapshark.com/api/1.0';
//  static const String _baseDeal = 'https://www.cheapshark.com/api/1.0/deals?';
  final http.Client _client;
  final Duration timeout;

  final Map<String, dynamic> _cache = {};

  CheapSharkGestor(
      {http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();
//buscador real

  Future<List<Juego>> searchByTitle(
    String title,
    int precio,
    int valoraciones,
    bool oferta,
    bool filtrar,
    List<String> storeIDs, {
    int limit = 5,
    bool useCache = true,
  }) async {
    final storeKey = storeIDs.join(",");

    final key =
        'search_deals:$title:$precio:$valoraciones:$oferta:$limit:$filtrar:$storeKey';

    if (useCache && _cache.containsKey(key)) {
      return List<Juego>.from(_cache[key]);
    }

    final raw = await searchByName(
      title,
      precio,
      valoraciones,
      oferta,
      filtrar,
      storeIDs,
      limit: limit,
      useCache: useCache,
    );

    if (raw.isEmpty) {
      _cache[key] = <Juego>[];
      return [];
    }

    final results = <Juego>[];

    for (final item in raw) {
      final steamAppId = item['steamAppID']?.toString();
      if (steamAppId == null || steamAppId.isEmpty) continue;

      final storeId = item['storeID']?.toString() ?? '';

      final salePrice = item['salePrice']?.toString() ?? '0';

      final minimoHistorico =
          double.tryParse(salePrice.replaceAll(',', '.')) ?? 0.0;

      final releaseDateUnix = item['releaseDate'];

      String releaseDate = '';
      if (releaseDateUnix is int && releaseDateUnix > 0) {
        final date =
            DateTime.fromMillisecondsSinceEpoch(releaseDateUnix * 1000);
        releaseDate = date.toIso8601String();
      }

      final juego = Juego(
        idCheapshark: item['gameID']?.toString() ?? '',
        title: item['title']?.toString() ?? '',
        steamApiID: steamAppId,
        normalPrice: item['normalPrice']?.toString() ?? '0',
        steamRatingPercent: item['steamRatingPercent']?.toString() ?? '',
        steamRatingCount: item['steamRatingCount']?.toString() ?? '',
        metaCriticScore: item['metacriticScore']?.toString() ?? '',
        metacriticLink: item['metacriticLink']?.toString() ?? '',
        releaseDate: releaseDate,
        thumb: item['thumb']?.toString() ?? '',
        minimoHistorico: minimoHistorico,
        fechaMinimoHistorico: '',
        storeid: storeId,
        listaPorTienda: const [],
      );

      results.add(juego);
    }

    _cache[key] = results;
    return results;
  }

  Future<List<Map<String, dynamic>>> searchByName(
    String title,
    int precio,
    int valoraciones,
    bool oferta,
    bool filtrar,
    List<String> storeIDs, {
    int limit = 5,
    bool useCache = true,
  }) async {
    final storeKey = storeIDs.join(",");

    final key =
        'raw_deals:$title:$precio:$valoraciones:$oferta:$limit:$filtrar:$storeKey';

    if (useCache && _cache.containsKey(key)) {
      final cached = List<Map<String, dynamic>>.from(_cache[key]);
      debugLog('cache hit for $key (items=${cached.length})');
      return cached;
    }

    final queryParams = {
      'title': title,
      'pageSize': limit.toString(),
    };

    if (precio > 0 && precio < 60) {
      queryParams['upperPrice'] = precio.toString();
    }

    if (valoraciones > 40) {
      queryParams['steamRating'] = valoraciones.toString();
    }

    queryParams['onSale'] = oferta ? '1' : '0';

    if (storeIDs.isNotEmpty) {
      queryParams['storeID'] = storeIDs.join(",");
    }

    final url = Uri.https(
      'www.cheapshark.com',
      '/api/1.0/deals',
      queryParams,
    );

    debugLog('HTTP GET $url');

    try {
      final res = await _client.get(url).timeout(timeout);

      if (res.statusCode != 200) {
        debugLog('Non-200 status: ${res.statusCode}');
        return [];
      }

      final List<dynamic> body = json.decode(res.body);

      final rawList = body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _cache[key] = rawList;
      return rawList;
    } on TimeoutException {
      debugLog('Timeout on $url');
      return [];
    } catch (e, st) {
      debugLog('Error on searchByName: $e\n$st');
      return [];
    }
  }

  Future<Juego?> fetchByGameId(String gameId, {bool useCache = true}) async {
    final raw = await fetchRawByGameId(gameId, useCache: useCache);
    if (raw == null) return null;

    final info = raw['info'] ?? {};
    final deals = raw['deals'] as List<dynamic>? ?? [];

    final stores = await _fetchStores();

    final List<DatoJuegoPorTienda> listaTiendas = deals.map((d) {
      final storeId = d['storeID'].toString();
      final store = stores[storeId];

      return DatoJuegoPorTienda(
        storeId: storeId,
        storeName: store?['name'] ?? '',
        dealId: d['dealID'],
        price: double.tryParse(d['price']) ?? 0.0,
        retailPrice: double.tryParse(d['retailPrice']) ?? 0.0,
        urlIcono: store?['icon'] ?? '',
      );
    }).toList();

    final cheapestEver = raw['cheapestPriceEver']?['price'];

    final juego = Juego(
      idCheapshark: info['gameID']?.toString() ?? gameId,
      title: info['title'] ?? '',
      steamApiID: info['steamAppID']?.toString() ?? '',
      normalPrice: info['normalPrice']?.toString() ?? '',
      steamRatingPercent: info['steamRatingPercent']?.toString() ?? '',
      steamRatingCount: info['steamRatingCount']?.toString() ?? '',
      metaCriticScore: info['metacriticScore']?.toString() ?? '',
      metacriticLink: info['metacriticLink']?.toString() ?? '',
      releaseDate: info['releaseDate']?.toString() ?? '',
      thumb: info['thumb']?.toString() ?? '',
      minimoHistorico: double.tryParse(cheapestEver ?? '') ?? 0.0,
      fechaMinimoHistorico: '',
      listaPorTienda: listaTiendas,
      storeid: '',
    );

    printJuego(juego, prefix: '[DETAIL]');

    return juego;
  }

  Future<Map<String, dynamic>?> fetchRawByGameId(String gameId,
      {bool useCache = true}) async {
    final key = 'raw_game:$gameId';
    if (useCache && _cache.containsKey(key)) {
      debugLog('cache hit for $key');
      return _cache[key] as Map<String, dynamic>?;
    }

    final url = Uri.parse('$_base/games/$gameId');
    debugLog('HTTP GET $url');

    try {
      final res = await _client.get(url).timeout(timeout);
      debugLog(
          'Detail Response status: ${res.statusCode} for $url (bytes=${res.body.length})');
      if (res.statusCode != 200) {
        debugLog('Non-200 status for detail: ${res.statusCode}');
        return null;
      }
      final Map<String, dynamic> body =
          json.decode(res.body) as Map<String, dynamic>;
      _cache[key] = body;
      return body;
    } on TimeoutException {
      debugLog('Timeout on detail $url');
      return null;
    } catch (e, st) {
      debugLog('Error on fetchRawByGameId: $e\n$st');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }

  void debugLog(String msg) {
    debugPrint('[CheapSharkGestor] $msg');
  }

  void printJuego(Juego juego, {String prefix = ''}) {
    debugLog('$prefix JUEGO ----------------------------');
    debugLog('CheapShark ID: ${juego.idCheapshark}');
    debugLog('Título: ${juego.title}');
    debugLog('Steam App ID: ${juego.steamApiID}');
    debugLog('Precio normal: ${juego.normalPrice}');
    debugLog('Steam Rating %: ${juego.steamRatingPercent}');
    debugLog('Steam Rating Count: ${juego.steamRatingCount}');
    debugLog('Metacritic Score: ${juego.metaCriticScore}');
    debugLog('Metacritic Link: ${juego.metacriticLink}');
    debugLog('Release Date: ${juego.releaseDate}');
    debugLog('Thumb: ${juego.thumb}');
    debugLog('Mínimo histórico: ${juego.minimoHistorico}');
    debugLog('Fecha mínimo histórico: ${juego.fechaMinimoHistorico}');
    debugLog('Tiendas: ${juego.listaPorTienda.length}');

    for (final tienda in juego.listaPorTienda) {
      printTienda(tienda);
    }

    debugLog('------------------------------------');
  }

  void printTienda(DatoJuegoPorTienda tienda) {
    debugLog('  TIENDA ----------------------------');
    debugLog('  Store ID: ${tienda.storeId}');
    debugLog('  Deal ID: ${tienda.dealId}');
    debugLog('  Precio oferta: ${tienda.price}');
    debugLog('  Precio base: ${tienda.retailPrice}');
    debugLog('  ----------------------------------');
  }

  void clearCache() {
    _cache.clear();
  }

  Future<List<Juego>> completarDatosFaltantes(
    List<Juego> juegos, {
    bool useCache = true,
  }) async {
    final List<Future<Juego>> futures = [];

    for (final juego in juegos) {
      futures.add(_completarJuegoIndividual(juego, useCache: useCache));
    }

    final juegosCompletos = await Future.wait(futures);
    return juegosCompletos;
  }

  Future<Juego> _completarJuegoIndividual(
    Juego juego, {
    bool useCache = true,
  }) async {
    if (juego.idCheapshark.isEmpty) return juego;

    final raw = await fetchRawByGameId(
      juego.idCheapshark,
      useCache: useCache,
    );
    printJuego(juego, prefix: '[Incompleto]');
    if (raw == null) return juego;

    final juegoActualizado = juego.copyWith(
      steamRatingPercent: raw['steamRatingPercent']?.toString() ?? '',
      steamRatingCount: raw['steamRatingCount']?.toString() ?? '',
      releaseDate: raw['releaseDate']?.toString() ?? '',
    );

    printJuego(juegoActualizado, prefix: '[COMPLETADO]');

    return juegoActualizado;
  }

  List<String> parseSteamDescription(String rawDescription) {
    final List<String> descripcion = [];

    final imgRegex = RegExp(r'<img[^>]*src="(https:[^"]+)"[^>]*>');
    final matches = imgRegex.allMatches(rawDescription);

    int lastIndex = 0;

    for (final match in matches) {
      final textBefore = rawDescription.substring(lastIndex, match.start);

      final clean = cleanText(textBefore);

      if (clean.isNotEmpty) {
        descripcion.add(clean);
      }

      final imgUrl = match.group(1);
      if (imgUrl != null && imgUrl.isNotEmpty) {
        descripcion.add(imgUrl);
      }

      lastIndex = match.end;
    }

    final remaining = rawDescription.substring(lastIndex);
    final cleanRemaining = cleanText(remaining);

    if (cleanRemaining.isNotEmpty) {
      descripcion.add(cleanRemaining);
    }

    return descripcion;
  }

  String cleanText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'width="?[\d]+"?'), '')
        .replaceAll(RegExp(r'height="?[\d]+"?'), '')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

// datos steam
  Future<DataJuego?> fetchSteamGameData(
    String steamAppId, {
    bool useCache = true,
  }) async {
    if (steamAppId.isEmpty) return null;

    final key = 'steam_full:$steamAppId';

    if (useCache && _cache.containsKey(key)) {
      debugLog('cache hit for $key');
      return _cache[key] as DataJuego;
    }

    final url = Uri.https(
      'store.steampowered.com',
      '/api/appdetails',
      {
        'appids': steamAppId,
        'l': 'spanish',
      },
    );

    debugLog('HTTP GET $url');

    try {
      final res = await _client.get(url).timeout(timeout);

      if (res.statusCode != 200) return null;

      final Map<String, dynamic> body = json.decode(res.body);
      final appData = body[steamAppId];

      if (appData == null || appData['success'] != true) return null;

      final data = appData['data'];

      final name = data['name'] ?? '';
      final date = data['release_date']?['date'] ?? '';
      String rawDescription = data['detailed_description'] ?? '';

      rawDescription = rawDescription
          .replaceAll(RegExp(r'width="\d+"'), '')
          .replaceAll(RegExp(r'height="\d+"'), '')
          .replaceAll(RegExp(r'width=\d+'), '')
          .replaceAll(RegExp(r'height=\d+'), '');

      List<String> descripcion = parseSteamDescription(rawDescription);

      final List<String> screenshots = (data['screenshots'] as List<dynamic>?)
              ?.map((e) => e['path_full'].toString())
              .toList() ??
          [];

      final List<Map<String, String>> movies =
          (data['movies'] as List<dynamic>?)
                  ?.map((e) {
                    final video = e['mp4']?['max'] ??
                        e['mp4']?['480'] ??
                        e['hls_h264'] ??
                        '';

                    final thumbnail = e['thumbnail'] ?? e['webm']?['max'] ?? '';

                    return {
                      "video": video.toString(),
                      "thumbnail": thumbnail.toString(),
                    };
                  })
                  .where((m) => m["video"]!.isNotEmpty)
                  .toList() ??
              [];

      Map<String, String> requisitosMinimos = {};
      Map<String, String> requisitosRecomendados = {};

      String limpiarHtml(String html) {
        return html.replaceAll(RegExp(r'<[^>]*>'), '');
      }

      void parseRequisitos(String html, Map<String, String> target) {
        final limpio = limpiarHtml(html);
        final lineas = limpio.split('\n');

        for (final linea in lineas) {
          if (linea.contains(':')) {
            final partes = linea.split(':');
            if (partes.length >= 2) {
              final key = partes[0].trim();
              final value = partes.sublist(1).join(':').trim();
              if (key.isNotEmpty && value.isNotEmpty) {
                target[key] = value;
              }
            }
          }
        }
      }

      final pcRequirements = data['pc_requirements'];

      if (pcRequirements != null) {
        if (pcRequirements['minimum'] != null) {
          parseRequisitos(pcRequirements['minimum'], requisitosMinimos);
        }

        if (pcRequirements['recommended'] != null) {
          parseRequisitos(
              pcRequirements['recommended'], requisitosRecomendados);
        }
      }

      final String developers = (data['developers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .join(', ') ??
          '';

      final String publisher = (data['publishers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .join(', ') ??
          '';

      final String recommendations =
          data['recommendations']?['total']?.toString() ?? '0';

      final String requiredAge = data['required_age']?.toString() ?? '0';

      final List<String> genres = (data['genres'] as List<dynamic>?)
              ?.map((e) => e['description'].toString())
              .toList() ??
          [];

      final juego = DataJuego(
        name: name,
        descripcion: descripcion,
        screenshots: screenshots,
        movies: movies,
        date: date,
        requisitosMinimos: requisitosMinimos,
        requisitosRecomendados: requisitosRecomendados,
        developers: developers,
        publisher: publisher,
        recommendations: recommendations,
        requiredAge: requiredAge,
        genres: genres,
      );

      _cache[key] = juego;

      debugLog('Steam DataJuego creado correctamente');

      return juego;
    } on TimeoutException {
      debugLog('Timeout Steam API');
      return null;
    } catch (e, st) {
      debugLog('Error fetchSteamGameData: $e\n$st');
      return null;
    }
  }

  Future<Map<String, Map<String, String>>> _fetchStores() async {
    const key = 'stores_full';

    if (_cache.containsKey(key)) {
      return Map<String, Map<String, String>>.from(_cache[key]);
    }

    final url = Uri.parse('https://www.cheapshark.com/api/1.0/stores');

    try {
      final res = await _client.get(url).timeout(timeout);

      if (res.statusCode != 200) {
        debugLog("Error obteniendo stores: ${res.statusCode}");
        return {};
      }

      final List<dynamic> body = json.decode(res.body);

      final Map<String, Map<String, String>> storeMap = {};

      for (final s in body) {
        final id = s['storeID'].toString();
        final name = s['storeName'] ?? '';
        final icon = s['images']?['icon'];

        storeMap[id] = {
          "name": name,
          "icon": icon != null ? "https://www.cheapshark.com$icon" : "",
        };
      }

      _cache[key] = storeMap;

      return storeMap;
    } catch (e, st) {
      debugLog("Error fetch stores: $e\n$st");
      return {};
    }
  }

  Future<List<DatoJuegoPorTienda>> fetchDealsByCheapSharkId(
    String cheapsharkId, {
    bool useCache = true,
  }) async {
    final key = 'deals_by_id:$cheapsharkId';

    if (useCache && _cache.containsKey(key)) {
      debugLog('cache hit for $key');
      return List<DatoJuegoPorTienda>.from(_cache[key]);
    }

    final url = Uri.https(
      'www.cheapshark.com',
      '/api/1.0/games',
      {'id': cheapsharkId},
    );

    debugLog('HTTP GET $url');

    try {
      final res = await _client.get(url).timeout(timeout);

      if (res.statusCode != 200) {
        debugLog('Non-200 status: ${res.statusCode}');
        return [];
      }

      final Map<String, dynamic> body = json.decode(res.body);

      final List<dynamic> deals = body['deals'] ?? [];

      final stores = await _fetchStores();

      final List<DatoJuegoPorTienda> listaTiendas = deals.map((d) {
        final storeId = d['storeID'].toString();
        final store = stores[storeId];

        return DatoJuegoPorTienda(
          storeId: storeId,
          storeName: store?['name'] ?? '',
          dealId: d['dealID'],
          price: double.tryParse(d['price']) ?? 0.0,
          retailPrice: double.tryParse(d['retailPrice']) ?? 0.0,
          urlIcono: store?['icon'] ?? '',
        );
      }).toList();

      _cache[key] = listaTiendas;

      debugLog(
          'Tiendas encontradas para $cheapsharkId: ${listaTiendas.length}');

      return listaTiendas;
    } on TimeoutException {
      debugLog('Timeout en CheapShark API');
      return [];
    } catch (e, st) {
      debugLog('Error fetchDealsByCheapSharkId: $e\n$st');
      return [];
    }
  }
}
