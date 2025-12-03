import 'package:proyectocomparador/models/juegoPorTienda.dart';

class Juego {
  String idCheapshark;
  String id;
  String nombre;
  String steamApiID;
  String precioBase;
  String steamRating;
  String cuantasResenas;
  String metaCriticsRating;
  String metacriticLink;
  String fechaDeSalida;
  String publisher;
  String steamWorks;
  String thumb;
  double minimoHistorico;
  String fechaMinimoHistorico;
  List<DatoJuegoPorTienda> listaPorTienda;

  Juego({
    required this.idCheapshark,
    required this.id,
    required this.nombre,
    required this.steamApiID,
    required this.precioBase,
    required this.steamRating,
    required this.cuantasResenas,
    required this.metaCriticsRating,
    required this.metacriticLink,
    required this.fechaDeSalida,
    required this.publisher,
    required this.steamWorks,
    required this.thumb,
    required this.minimoHistorico,
    required this.fechaMinimoHistorico,
    this.listaPorTienda = const [],
  });

  // Convertir a mapa (para JSON o Firestore)
  Map<String, dynamic> toJson() {
    return {
      'idCheapshark': idCheapshark,
      'id': id,
      'nombre': nombre,
      'steamApiID': steamApiID,
      'precioBase': precioBase,
      'steamRating': steamRating,
      'cuantasResenas': cuantasResenas,
      'metaCriticsRating': metaCriticsRating,
      'metacriticLink': metacriticLink,
      'fechaDeSalida': fechaDeSalida,
      'publisher': publisher,
      'steamWorks': steamWorks,
      'thumb': thumb,
      'minimoHistorico': minimoHistorico,
      'fechaMinimoHistorico': fechaMinimoHistorico,
      'listaPorTienda': listaPorTienda.map((e) => e.toJson()).toList(),
    };
  }

  // Crear instancia desde un mapa
  factory Juego.fromJson(Map<String, dynamic> json) {
    return Juego(
      idCheapshark: json['idCheapshark'],
      id: json['id'],
      nombre: json['nombre'],
      steamApiID: json['steamApiID'],
      precioBase: json['precioBase'],
      steamRating: json['steamRating'],
      cuantasResenas: json['cuantasResenas'],
      metaCriticsRating: json['metaCriticsRating'],
      metacriticLink: json['metacriticLink'],
      fechaDeSalida: json['fechaDeSalida'],
      publisher: json['publisher'],
      steamWorks: json['steamWorks'],
      thumb: json['thumb'],
      minimoHistorico: (json['minimoHistorico'] as num).toDouble(),
      fechaMinimoHistorico: json['fechaMinimoHistorico'],
      listaPorTienda: json['listaPorTienda'] != null
          ? List<DatoJuegoPorTienda>.from((json['listaPorTienda'] as List)
              .map((item) => DatoJuegoPorTienda.fromJson(item)))
          : [],
    );
  }
}
