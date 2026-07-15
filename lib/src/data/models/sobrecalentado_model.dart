// Representa un renglón de temperatura específica dentro de un bloque de presión constante
class PropiedadSobrecalentada {
  final double t; // Temperatura (°C)
  final double v; // Volumen específico (m³/kg)
  final double u; // Energía interna (kJ/kg)
  final double h; // Entalpía (kJ/kg)
  final double s; // Entropía (kJ/kg·K)

  PropiedadSobrecalentada({
    required this.t,
    required this.v,
    required this.u,
    required this.h,
    required this.s,
  });

  factory PropiedadSobrecalentada.fromMap(Map<String, dynamic> map) {
    final tValue = map['T'];
    final vValue = map['v'];
    final uValue = map['u'];
    final hValue = map['h'];
    final sValue = map['s'];

    if (tValue is! num ||
        vValue is! num ||
        uValue is! num ||
        hValue is! num ||
        sValue is! num) {
      throw const FormatException('Propiedad sobrecalentada incompleta');
    }

    return PropiedadSobrecalentada(
      t: tValue.toDouble(),
      v: vValue.toDouble(),
      u: uValue.toDouble(),
      h: hValue.toDouble(),
      s: sValue.toDouble(),
    );
  }
}

// Representa un bloque completo de presión (Ej: Bloque de P = 10.0 kPa)
class BloquePresionSobrecalentado {
  final double p; // Presión del bloque (kPa)
  final double tSat; // Temperatura de saturación a esa presión (°C)
  final List<PropiedadSobrecalentada> propiedadesPorT;

  BloquePresionSobrecalentado({
    required this.p,
    required this.tSat,
    required this.propiedadesPorT,
  });

  factory BloquePresionSobrecalentado.fromMap(Map<String, dynamic> map) {
    final pValue = map['P'];
    final tSatValue = map['T_sat'];
    final listaT = map['propiedades_por_T'];

    if (pValue is! num || tSatValue is! num || listaT is! List) {
      throw const FormatException('Bloque sobrecalentado incompleto');
    }

    final listaPropiedades = <PropiedadSobrecalentada>[];
    for (final item in listaT) {
      if (item is! Map) continue;
      try {
        final prop = PropiedadSobrecalentada.fromMap(
          Map<String, dynamic>.from(item),
        );
        listaPropiedades.add(prop);
      } catch (_) {
        // Se omiten propiedades incompletas.
      }
    }

    if (listaPropiedades.isEmpty) {
      throw const FormatException(
        'Bloque sobrecalentado sin propiedades válidas',
      );
    }

    return BloquePresionSobrecalentado(
      p: pValue.toDouble(),
      tSat: tSatValue.toDouble(),
      propiedadesPorT: listaPropiedades,
    );
  }
}
