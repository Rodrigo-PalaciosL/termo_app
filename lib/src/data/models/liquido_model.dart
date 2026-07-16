// Representa un renglón de temperatura específica dentro de un bloque de presión constante para líquido comprimido
class PropiedadLiquido {
  final double t; // Temperatura (°C)
  final double v; // Volumen específico (m³/kg)
  final double u; // Energía interna (kJ/kg)
  final double h; // Entalpía (kJ/kg)
  final double s; // Entropía (kJ/kg·K)

  PropiedadLiquido({
    required this.t,
    required this.v,
    required this.u,
    required this.h,
    required this.s,
  });

  factory PropiedadLiquido.fromMap(Map<String, dynamic> map) {
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
      throw const FormatException('Propiedad de líquido incompleta');
    }

    return PropiedadLiquido(
      t: tValue.toDouble(),
      v: vValue.toDouble(),
      u: uValue.toDouble(),
      h: hValue.toDouble(),
      s: sValue.toDouble(),
    );
  }
}

// Representa un bloque completo de presión para la zona de líquido comprimido
class BloquePresionLiquido {
  final double p; // Presión del bloque (kPa)
  final dynamic tSat; // Temperatura de saturación a esa presión (°C) o "N/A"
  final List<PropiedadLiquido> propiedadesPorT;

  BloquePresionLiquido({
    required this.p,
    required this.tSat,
    required this.propiedadesPorT,
  });

  factory BloquePresionLiquido.fromMap(Map<String, dynamic> map) {
    final pValue = map['P'];
    final tSatValue = map['T_sat'];
    final listaT = map['propiedades_por_T'];

    if (pValue is! num || listaT is! List) {
      throw const FormatException('Bloque de líquido incompleto');
    }

    final listaPropiedades = <PropiedadLiquido>[];
    for (final item in listaT) {
      if (item is! Map) continue;
      try {
        final prop = PropiedadLiquido.fromMap(
          Map<String, dynamic>.from(item),
        );
        listaPropiedades.add(prop);
      } catch (_) {
        // Se omiten propiedades incompletas.
      }
    }

    if (listaPropiedades.isEmpty) {
      throw const FormatException(
        'Bloque de líquido sin propiedades válidas',
      );
    }

    return BloquePresionLiquido(
      p: pValue.toDouble(),
      tSat: tSatValue,
      propiedadesPorT: listaPropiedades,
    );
  }
}
