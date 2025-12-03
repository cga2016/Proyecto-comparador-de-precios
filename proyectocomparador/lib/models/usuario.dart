class Usuario {
  int id;
  String nick;
  String correo;
  String contrasena;
  String imagenRuta;
  List<String> listaFavoritos;

  Usuario({
    required this.id,
    required this.nick,
    required this.correo,
    required this.contrasena,
    required this.imagenRuta,
    List<String>? listaFavoritos,
  }) : listaFavoritos = listaFavoritos ?? [];

  void setListaFavoritos(List<String> lista) {
    listaFavoritos = List<String>.from(lista);
  }

  List<String> getListaFavoritos() {
    return List<String>.from(listaFavoritos);
  }

  void agregarFavorito(String favorito) {
    if (!listaFavoritos.contains(favorito)) {
      listaFavoritos.add(favorito);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nick': nick,
      'correo': correo,
      'contrasena': contrasena,
      'imagenRuta': imagenRuta,
      'listaFavoritos': listaFavoritos,
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nick: json['nick'] ?? '',
      correo: json['correo'] ?? '',
      contrasena: json['contrasena'] ?? '',
      imagenRuta: json['imagenRuta'] ?? '',
      listaFavoritos: (json['listaFavoritos'] != null)
          ? List<String>.from(json['listaFavoritos'])
          : [],
    );
  }
}
