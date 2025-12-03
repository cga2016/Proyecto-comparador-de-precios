class DatoJuegoPorTienda {
  String id;
  String dealId;
  double precioOferta;
  double precioBase;

  DatoJuegoPorTienda({
    required this.id,
    required this.dealId,
    required this.precioOferta,
    required this.precioBase,
  });

  // Convertir a mapa (para Firestore o JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dealId': dealId,
      'precioOferta': precioOferta,
      'precioBase': precioBase,
    };
  }

  // Crear instancia desde un mapa
  factory DatoJuegoPorTienda.fromJson(Map<String, dynamic> json) {
    return DatoJuegoPorTienda(
      id: json['id'],
      dealId: json['dealId'],
      precioOferta: (json['precioOferta'] as num).toDouble(),
      precioBase: (json['precioBase'] as num).toDouble(),
    );
  }
}
