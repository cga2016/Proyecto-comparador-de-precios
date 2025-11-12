class Usuario {
  final String name;
  final String correo;
  final String contrasena;

  Usuario({
    required this.name,
    required this.correo,
    required this.contrasena,
  });

  factory Usuario.fromMap(Map<String, dynamic> data) {
    return Usuario(
      name: data['name'] ?? '',
      correo: data['correo'] ?? '',
      contrasena: data['contraseña'] ?? '',
    );
  }

  get nombre => null;

  @override
  String toString() {
    return "  nombre: $name  correo: $correo  contraseña: $contrasena";
  }
}
