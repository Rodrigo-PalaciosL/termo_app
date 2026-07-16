import 'liquido_model.dart';
import 'saturacion_model.dart';
import 'sobrecalentado_model.dart';

class TermoDatabase {
  // Listas con tipado fuerte listas para indexar e interpolar
  final List<PuntoSaturacion> tablaSaturacion;
  final List<BloquePresionSobrecalentado> tablaSobrecalentado;
  final List<BloquePresionLiquido> tablaLiquido;

  TermoDatabase({
    required this.tablaSaturacion,
    required this.tablaSobrecalentado,
    required this.tablaLiquido,
  });

  // Metodo inicializador para poblar la base desde las respuestas JSON de los archivos
  factory TermoDatabase.fromRawData({
    required List<dynamic> jsonSaturacion,
    required List<dynamic> jsonSobrecalentado,
    List<dynamic>? jsonLiquido,
  }) {
    final satParsed = jsonSaturacion
        .map((e) => PuntoSaturacion.fromMap(e as Map<String, dynamic>))
        .toList();

    final sobreParsed = <BloquePresionSobrecalentado>[];
    for (final item in jsonSobrecalentado) {
      if (item is! Map) continue;
      try {
        final bloque = BloquePresionSobrecalentado.fromMap(
          Map<String, dynamic>.from(item),
        );
        sobreParsed.add(bloque);
      } catch (_) {
        // Se omiten bloques incompletos del JSON.
      }
    }

    final liqParsed = <BloquePresionLiquido>[];
    if (jsonLiquido != null) {
      for (final item in jsonLiquido) {
        if (item is! Map) continue;
        try {
          final bloque = BloquePresionLiquido.fromMap(
            Map<String, dynamic>.from(item),
          );
          liqParsed.add(bloque);
        } catch (_) {}
      }
    }

    return TermoDatabase(
      tablaSaturacion: satParsed,
      tablaSobrecalentado: sobreParsed,
      tablaLiquido: liqParsed,
    );
  }
}
