class DatoJuegoPorTienda {
  String storeId;
  String storeName;
  String dealId;
  double price;
  double retailPrice;
  String urlIcono;

  DatoJuegoPorTienda({
    required this.storeId,
    required this.storeName,
    required this.dealId,
    required this.price,
    required this.retailPrice,
    required this.urlIcono,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': storeId,
      'storeName': storeName,
      'dealId': dealId,
      'precioOferta': price,
      'precioBase': retailPrice,
      'urlIcono': urlIcono,
    };
  }

  factory DatoJuegoPorTienda.fromJson(Map<String, dynamic> json) {
    return DatoJuegoPorTienda(
      storeId: json['id'],
      storeName: json['storeName'] ?? '',
      dealId: json['dealId'],
      price: (json['precioOferta'] as num).toDouble(),
      retailPrice: (json['precioBase'] as num).toDouble(),
      urlIcono: json['urlIcono'] ?? '',
    );
  }
}
