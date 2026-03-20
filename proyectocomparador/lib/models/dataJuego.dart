// ignore: file_names
class DataJuego {
  final String name;
  final List<String> descripcion;
  final List<String> screenshots;
  final List<Map<String, String>> movies;
  final String date;
  final Map<String, String> requisitosMinimos;
  final Map<String, String> requisitosRecomendados;
  final String developers;
  final String publisher;
  final String recommendations;
  final String requiredAge;
  final List<String> genres;

  DataJuego({
    required this.name,
    required this.descripcion,
    required this.screenshots,
    required this.movies,
    required this.date,
    required this.requisitosMinimos,
    required this.requisitosRecomendados,
    required this.developers,
    required this.publisher,
    required this.recommendations,
    required this.requiredAge,
    required this.genres,
  });
}
