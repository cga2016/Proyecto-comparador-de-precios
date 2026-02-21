class DatoJuegoPorTienda {
  String storeId;
  String dealId;
  double price;
  double retailPrice;

  DatoJuegoPorTienda({
    required this.storeId,
    required this.dealId,
    required this.price,
    required this.retailPrice,
  });

  get storeName => null;

  get precio => null;

  Map<String, dynamic> toJson() {
    return {
      'id': storeId,
      'dealId': dealId,
      'precioOferta': price,
      'precioBase': retailPrice,
    };
  }

  factory DatoJuegoPorTienda.fromJson(Map<String, dynamic> json) {
    return DatoJuegoPorTienda(
      storeId: json['id'],
      dealId: json['dealId'],
      price: (json['precioOferta'] as num).toDouble(),
      retailPrice: (json['precioBase'] as num).toDouble(),
    );
  }
}
