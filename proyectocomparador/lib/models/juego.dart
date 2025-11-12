// ignore: file_names
class Juego {
  final String id;
  final String titulo;
  final String descripcion;
  final String urlImagenGrande;
  final String urlImagenPequena;
  final double precioActual;
  final double precioMinimo;
  final double review;
  final String desarrollador;

  Juego({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.urlImagenGrande,
    required this.urlImagenPequena,
    required this.precioActual,
    required this.precioMinimo,
    required this.review,
    required this.desarrollador,
  });

  factory Juego.fromJson(Map<String, dynamic> json) {
    return Juego(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      urlImagenGrande: json['urlImagenGrande'],
      urlImagenPequena: json['urlImagenPequena'],
      precioActual: (json['precioActual'] as num).toDouble(),
      precioMinimo: (json['precioMinimo'] as num).toDouble(),
      review: (json['review'] as num).toDouble(),
      desarrollador: json['desarrollador'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'urlImagenGrande': urlImagenGrande,
      'urlImagenPequena': urlImagenPequena,
      'precioActual': precioActual,
      'precioMinimo': precioMinimo,
      'review': review,
      'desarrollador': desarrollador,
    };
  }
}
