// ignore_for_file: file_names
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:proyectocomparador/models/juego.dart';

class CheapSharkGestor {
  static const String _base = 'https://www.cheapshark.com/api/1.0';
  final http.Client _client;
  final Duration timeout;

  final Map<String, dynamic> _cache = {};

  CheapSharkGestor(
      {http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();

  /// Busca y devuelve una lista de `Juego` adaptados a tu nuevo modelo.
  Future<List<Juego>> searchByTitle(String title,
      {int limit = 5, bool useCache = true}) async {
    final key = 'search:$title:$limit';
    if (useCache && _cache.containsKey(key)) {
      final cached = _cache[key] as List<Juego>;
      debugLog('cache hit for $key (items=${cached.length})');
      return cached;
    }

    final raw = await searchByName(title, limit: limit, useCache: useCache);
    if (raw.isEmpty) {
      _cache[key] = <Juego>[];
      return [];
    }

    final results = <Juego>[];
    for (final item in raw) {
      final gameId = item['gameID']?.toString() ?? '';
      final nombre = item['external']?.toString() ?? '';
      final cheapestStr = (item['cheapest'] ?? '').toString();
      final cheapestDouble =
          double.tryParse(cheapestStr.replaceAll(',', '.')) ?? 0.0;
      final thumb = item['thumb']?.toString() ?? '';

      results.add(Juego(
        idCheapshark: gameId,
        id: gameId,
        nombre: nombre,
        steamApiID: '',
        precioBase: cheapestStr.isNotEmpty ? cheapestStr : '0',
        steamRating: '',
        cuantasResenas: '',
        metaCriticsRating: '',
        metacriticLink: '',
        fechaDeSalida: '',
        publisher: '',
        steamWorks: '',
        thumb: thumb,
        minimoHistorico: cheapestDouble,
        fechaMinimoHistorico: '',
        listaPorTienda: const [],
      ));
    }

    _cache[key] = results;
    return results;
  }

  /// Obtiene y mapea un juego por su gameId a tu modelo `Juego`.
  Future<Juego?> fetchByGameId(String gameId, {bool useCache = true}) async {
    final key = 'game:$gameId';
    if (useCache && _cache.containsKey(key)) {
      debugLog('cache hit for $key');
      return _cache[key] as Juego?;
    }

    final raw = await fetchRawByGameId(gameId, useCache: useCache);
    if (raw == null) return null;

    try {
      final info =
          (raw['info'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final images =
          (raw['images'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      final idCheap = info['gameID']?.toString() ?? gameId;
      final nombre = info['title']?.toString() ?? '';
      // precio base: intentamos normalPrice -> price -> cheapest -> ''
      final precioBaseCandidate = (info['normalPrice'] ??
              info['price'] ??
              info['cheap'] ??
              info['cheapest'] ??
              '')
          .toString();
      // minimo historico: cheapestPriceEver.price si existe
      final cheapestEverRaw = raw['cheapestPriceEver'] is Map
          ? raw['cheapestPriceEver']['price']
          : null;
      final cheapestEver = cheapestEverRaw != null
          ? double.tryParse(cheapestEverRaw.toString().replaceAll(',', '.')) ??
              0.0
          : 0.0;

      // precio actual: buscar en deals[0].price si existe
      double precioActualDouble = 0.0;
      final deals = (raw['deals'] as List<dynamic>?) ?? [];
      if (deals.isNotEmpty) {
        precioActualDouble = double.tryParse(
                deals[0]['price']?.toString().replaceAll(',', '.') ?? '') ??
            precioActualDouble;
      } else {
        // fallback: usar cheapestEver o normalPrice parseado
        final parsedNormal =
            double.tryParse(precioBaseCandidate.replaceAll(',', '.')) ?? 0.0;
        precioActualDouble = cheapestEver > 0 ? cheapestEver : parsedNormal;
      }

      final thumb = (images['banner'] ??
              images['capsule'] ??
              images['thumb'] ??
              images['capLarge'] ??
              '')
          .toString();

      // NOTA: listaPorTienda queda vacía por defecto. Si quieres que parsee `deals`
      // a DatoJuegoPorTienda, pásame la estructura de esa clase y lo implemento.
      final juego = Juego(
        idCheapshark: idCheap,
        id: idCheap,
        nombre: nombre,
        steamApiID: info['steamAppID']?.toString() ?? '',
        precioBase: precioBaseCandidate.isNotEmpty
            ? precioBaseCandidate
            : precioActualDouble.toStringAsFixed(2),
        steamRating: '',
        cuantasResenas: '',
        metaCriticsRating: '',
        metacriticLink: '',
        fechaDeSalida: info['releaseDate']?.toString() ?? '',
        publisher: info['publisher']?.toString() ??
            info['developer']?.toString() ??
            '',
        steamWorks: info['steamworks']?.toString() ?? '',
        thumb: thumb,
        minimoHistorico: cheapestEver > 0 ? cheapestEver : precioActualDouble,
        fechaMinimoHistorico:
            '', // la API no devuelve fecha en cheapestPriceEver
        listaPorTienda: const [],
      );

      _cache[key] = juego;
      return juego;
    } catch (e, st) {
      debugLog('fetchByGameId parse error: $e\n$st');
      return null;
    }
  }

  /// búsqueda "cruda" que devuelve el JSON tal cual (lista de mapas)
  Future<List<Map<String, dynamic>>> searchByName(String title,
      {int limit = 5, bool useCache = true}) async {
    final key = 'raw_search:$title:$limit';
    if (useCache && _cache.containsKey(key)) {
      final cached = _cache[key] as List<Map<String, dynamic>>;
      debugLog('cache hit for $key (items=${cached.length})');
      return cached;
    }

    final url = Uri.parse(
        '$_base/games?title=${Uri.encodeQueryComponent(title)}&limit=$limit');
    debugLog('HTTP GET $url');

    try {
      final res = await _client.get(url).timeout(timeout);
      debugLog('Response status: ${res.statusCode} for $url');
      if (res.statusCode != 200) {
        debugLog('Non-200 status: ${res.statusCode}');
        return <Map<String, dynamic>>[];
      }

      final List<dynamic> body = json.decode(res.body) as List<dynamic>;
      debugLog(
          'Search returned ${body.length} items; bytes=${res.body.length}');
      final List<Map<String, dynamic>> rawList = [];
      for (final item in body) {
        if (item is Map<String, dynamic>) {
          rawList.add(item);
        } else if (item is Map) {
          rawList.add(Map<String, dynamic>.from(item));
        }
      }

      _cache[key] = rawList;
      return rawList;
    } on TimeoutException {
      debugLog('Timeout on $url');
      return <Map<String, dynamic>>[];
    } catch (e, st) {
      debugLog('Error on searchByName: $e\n$st');
      return <Map<String, dynamic>>[];
    }
  }

  /// detalle "crudo" por gameId
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

  void clearCache() => _cache.clear();

  void dispose() {
    _client.close();
  }

  void debugLog(String msg) {
    debugPrint('[CheapSharkGestor] $msg');
  }
}
