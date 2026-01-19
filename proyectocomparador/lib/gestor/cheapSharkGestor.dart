// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';

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
      final steamAppId = item['steamAppID']?.toString() ?? '';
      final nombre = item['external']?.toString() ?? '';
      final cheapestStr = (item['cheapest'] ?? '').toString();
      final cheapestDouble =
          double.tryParse(cheapestStr.replaceAll(',', '.')) ?? 0.0;
      final thumb = item['thumb']?.toString() ?? '';

      final juego = Juego(
        idCheapshark: gameId,
        title: nombre,
        steamApiID: steamAppId,
        normalPrice: cheapestStr.isNotEmpty ? cheapestStr : '0',
        steamRatingPercent: '',
        steamRatingCount: '',
        metaCriticScore: '',
        metacriticLink: '',
        releaseDate: '',
        thumb: thumb,
        minimoHistorico: cheapestDouble,
        fechaMinimoHistorico: '',
        listaPorTienda: const [],
      );

      printJuego(juego, prefix: '[SEARCH]');

      results.add(juego);
    }

    _cache[key] = results;
    return results;
  }

  Future<Juego?> fetchByGameId(String gameId, {bool useCache = true}) async {
    final raw = await fetchRawByGameId(gameId, useCache: useCache);
    if (raw == null) return null;

    final info = raw['info'] ?? {};
    final deals = raw['deals'] as List<dynamic>? ?? [];

    final tiendasPermitidas = {'1', '7', '11'};
    final List<DatoJuegoPorTienda> listaTiendas = deals
        .where((d) => tiendasPermitidas.contains(d['storeID']))
        .map((d) => DatoJuegoPorTienda(
              storeId: d['storeID'],
              dealId: d['dealID'],
              price: double.tryParse(d['price']) ?? 0.0,
              retailPrice: double.tryParse(d['retailPrice']) ?? 0.0,
            ))
        .toList();

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
    );

    printJuego(juego, prefix: '[DETAIL]');

    return juego;
  }

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
}
