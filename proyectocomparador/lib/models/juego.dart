import 'package:proyectocomparador/models/juegoPorTienda.dart';

//id 1 Steam
//id 7 gog
//id 11 humble bundle
//

class Juego {
  final String idCheapshark;
  final String title;
  final String steamApiID;

  final String normalPrice;
  final String steamRatingPercent;
  final String steamRatingCount;
  final String metaCriticScore;
  final String metacriticLink;
  final String releaseDate;
  final String thumb;
  final double minimoHistorico;
  final String fechaMinimoHistorico;
  final List<DatoJuegoPorTienda> listaPorTienda;
  final String storeid;

  Juego({
    required this.idCheapshark,
    required this.title,
    required this.steamApiID,
    required this.normalPrice,
    required this.steamRatingPercent,
    required this.steamRatingCount,
    required this.metaCriticScore,
    required this.metacriticLink,
    required this.releaseDate,
    required this.thumb,
    required this.minimoHistorico,
    required this.fechaMinimoHistorico,
    required this.storeid,
    this.listaPorTienda = const [],
  });

  Juego copyWith({
    String? idCheapshark,
    String? nombre,
    String? steamApiID,
    String? normalPrice,
    String? steamRatingPercent,
    String? steamRatingCount,
    String? metaCriticScore,
    String? metacriticLink,
    String? releaseDate,
    String? thumb,
    double? minimoHistorico,
    String? fechaMinimoHistorico,
    List<DatoJuegoPorTienda>? listaPorTienda,
  }) {
    return Juego(
      idCheapshark: idCheapshark ?? this.idCheapshark,
      title: nombre ?? this.title,
      steamApiID: steamApiID ?? this.steamApiID,
      normalPrice: normalPrice ?? this.normalPrice,
      steamRatingPercent: steamRatingPercent ?? this.steamRatingPercent,
      steamRatingCount: steamRatingCount ?? this.steamRatingCount,
      metaCriticScore: metaCriticScore ?? this.metaCriticScore,
      metacriticLink: metacriticLink ?? this.metacriticLink,
      releaseDate: releaseDate ?? this.releaseDate,
      thumb: thumb ?? this.thumb,
      minimoHistorico: minimoHistorico ?? this.minimoHistorico,
      fechaMinimoHistorico: fechaMinimoHistorico ?? this.fechaMinimoHistorico,
      listaPorTienda: listaPorTienda ?? this.listaPorTienda,
      storeid: storeid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCheapshark': idCheapshark,
      'nombre': title,
      'steamApiID': steamApiID,
      'normalPrice': normalPrice,
      'steamRatingPercent': steamRatingPercent,
      'steamRatingCount': steamRatingCount,
      'metaCriticScore': metaCriticScore,
      'metacriticLink': metacriticLink,
      'releaseDate': releaseDate,
      'thumb': thumb,
      'minimoHistorico': minimoHistorico,
      'fechaMinimoHistorico': fechaMinimoHistorico,
      'listaPorTienda': listaPorTienda.map((e) => e.toJson()).toList(),
    };
  }

  factory Juego.fromJson(Map<String, dynamic> json) {
    return Juego(
      idCheapshark: json['idCheapshark']?.toString() ?? '',
      title: json['nombre']?.toString() ?? '',
      steamApiID: json['steamApiID']?.toString() ?? '',
      normalPrice: json['normalPrice']?.toString() ?? '0',
      steamRatingPercent: json['steamRatingPercent']?.toString() ?? '',
      steamRatingCount: json['steamRatingCount']?.toString() ?? '',
      metaCriticScore: json['metaCriticScore']?.toString() ?? '',
      metacriticLink: json['metacriticLink']?.toString() ?? '',
      releaseDate: json['releaseDate']?.toString() ?? '',
      thumb: json['thumb']?.toString() ?? '',
      minimoHistorico: (json['minimoHistorico'] is num)
          ? (json['minimoHistorico'] as num).toDouble()
          : double.tryParse(json['minimoHistorico']?.toString() ?? '') ?? 0.0,
      fechaMinimoHistorico: json['fechaMinimoHistorico']?.toString() ?? '',
      listaPorTienda: (json['listaPorTienda'] as List<dynamic>?)
              ?.map((e) =>
                  DatoJuegoPorTienda.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      storeid: json['storeID']?.toString() ?? '',
    );
  }
}
