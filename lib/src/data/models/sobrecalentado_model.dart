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
    return PropiedadSobrecalentada(
      t: (map['T'] as num).toDouble(),
      v: (map['v'] as num).toDouble(),
      u: (map['u'] as num).toDouble(),
      h: (map['h'] as num).toDouble(),
      s: (map['s'] as num).toDouble(),
    );
  }
}

// Representa un bloque completo de presión (Ej: Bloque de P = 10.0 kPa)
class BloquePresionSobrecalentado {
  final double p;       // Presión del bloque (kPa)
  final double tSat;    // Temperatura de saturación a esa presión (°C)
  final List<PropiedadSobrecalentada> propiedadesPorT;

  BloquePresionSobrecalentado({
    required this.p,
    required this.tSat,
    required this.propiedadesPorT,
  });

  factory BloquePresionSobrecalentado.fromMap(Map<String, dynamic> map) {
    var listaT = map['propiedades_por_T'] as List;
    List<PropiedadSobrecalentada> listaPropiedades = listaT
        .map((item) => PropiedadSobrecalentada.fromMap(item as Map<String, dynamic>))
        .toList();

    return BloquePresionSobrecalentado(
      p: (map['P'] as num).toDouble(),
      tSat: (map['T_sat'] as num).toDouble(),
      propiedadesPorT: listaPropiedades,
    );
  }
}