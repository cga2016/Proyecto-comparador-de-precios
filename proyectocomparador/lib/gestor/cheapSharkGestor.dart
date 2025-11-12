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

  Future<List<Juego>> searchByTitle(String title,
      {int limit = 5, bool useCache = true}) async {
    final key = 'search:$title:$limit';
    if (useCache && _cache.containsKey(key)) {
      final cached = _cache[key] as List<Juego>;
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
      final titulo = item['external']?.toString() ?? '';
      final cheapest =
          double.tryParse((item['cheapest'] ?? '0').toString()) ?? 0.0;
      final thumbnail = item['thumb']?.toString() ?? '';

      results.add(Juego(
        id: gameId,
        titulo: titulo,
        descripcion: '',
        urlImagenGrande: thumbnail,
        urlImagenPequena: thumbnail,
        precioActual: cheapest,
        precioMinimo: cheapest,
        review: 0.0,
        desarrollador: '',
      ));
    }

    _cache[key] = results;
    return results;
  }

  Future<Juego?> fetchByGameId(String gameId, {bool useCache = true}) async {
    final key = 'game:$gameId';
    if (useCache && _cache.containsKey(key)) {
      return _cache[key] as Juego?;
    }

    final raw = await fetchRawByGameId(gameId, useCache: useCache);
    if (raw == null) return null;

    try {
      final info =
          (raw['info'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final images =
          (raw['images'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      final id = info['gameID']?.toString() ?? gameId;
      final titulo = info['title']?.toString() ?? '';
      final descripcion = info['desc']?.toString() ?? '';
      final normalPrice = double.tryParse(
              (info['normalPrice'] ?? info['price'] ?? '0').toString()) ??
          0.0;
      final cheapestEver = (raw['cheapestPriceEver']?['price'] != null)
          ? double.tryParse(raw['cheapestPriceEver']['price'].toString()) ?? 0.0
          : 0.0;

      double precioActual = 0.0;
      final deals = (raw['deals'] as List<dynamic>?) ?? [];
      if (deals.isNotEmpty) {
        precioActual =
            double.tryParse(deals[0]['price'].toString()) ?? precioActual;
      } else {
        precioActual = double.tryParse(
                (info['cheapest'] ?? cheapestEver ?? normalPrice).toString()) ??
            0.0;
      }

      final urlImagenGrande =
          (images['banner'] ?? images['capsule'] ?? images['thumb'] ?? '')
              .toString();
      final urlImagenPequena =
          (images['thumb'] ?? images['capLarge'] ?? images['capsule'] ?? '')
              .toString();

      final juego = Juego(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        urlImagenGrande: urlImagenGrande,
        urlImagenPequena: urlImagenPequena,
        precioActual: precioActual,
        precioMinimo: cheapestEver > 0 ? cheapestEver : precioActual,
        review: 0.0,
        desarrollador: info['developer']?.toString() ?? '',
      );

      _cache[key] = juego;
      return juego;
    } catch (e, st) {
      debugLog('fetchByGameId parse error: $e\n$st');
      return null;
    }
  }

// busqueda por nombre
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
      debugLog('Error on searchRawByTitle: $e\n$st');
      return <Map<String, dynamic>>[];
    }
  }

  /// busqueda pruebas
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
