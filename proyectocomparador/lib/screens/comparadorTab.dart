import 'package:flutter/material.dart';
import 'package:proyectocomparador/models/juego.dart';
import 'package:proyectocomparador/models/juegoPorTienda.dart';

class ComparadorTab extends StatelessWidget {
  final Juego juego;
  final List<DatoJuegoPorTienda> tiendas;
  final bool loading;

  const ComparadorTab({
    super.key,
    required this.juego,
    required this.tiendas,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tiendas.isEmpty) {
      return const Center(
        child: Text(
          "No se encontraron tiendas",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 25,
        headingRowColor: MaterialStateProperty.all(const Color(0xFF10002B)),
        dataRowColor: MaterialStateProperty.all(const Color(0xFF1A1A1A)),
        columns: const [
          DataColumn(label: Text("")),
          DataColumn(
            label: Text(
              "Precio base",
              style: TextStyle(color: Colors.white),
            ),
          ),
          DataColumn(
            label: Text(
              "Oferta",
              style: TextStyle(color: Colors.white),
            ),
          ),
          DataColumn(
            label: Text(
              "Desc.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        rows: tiendas.map((t) {
          final bool tieneOferta = t.price != t.retailPrice;

          return DataRow(
            cells: [
              DataCell(
                t.urlIcono.isNotEmpty
                    ? Image.network(
                        t.urlIcono,
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.store,
                            color: Colors.white54,
                          );
                        },
                      )
                    : const Icon(
                        Icons.store,
                        color: Colors.white54,
                      ),
              ),
              DataCell(
                Text(
                  "${t.retailPrice.toStringAsFixed(2)} €",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              DataCell(
                Text(
                  "${t.price.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    color: Color(0xFFC77DFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Icon(
                  tieneOferta ? Icons.check_circle : Icons.cancel,
                  color: tieneOferta ? Colors.green : Colors.red,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
