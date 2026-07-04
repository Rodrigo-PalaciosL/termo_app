class PuntoSaturacion {
  final double t;    // Temperatura (°C)
  final double pSat; // Presión de saturación (kPa)
  final double vf;   // Volumen específico líquido saturado (m³/kg)
  final double vg;   // Volumen específico vapor saturado (m³/kg)
  final double uf;   // Energía interna líquido saturado (kJ/kg)
  final double ug;   // Energía interna vapor saturado (kJ/kg)
  final double hf;   // Entalpía líquido saturado (kJ/kg)
  final double hg;   // Entalpía vapor saturado (kJ/kg)
  final double sf;   // Entropía líquido saturado (kJ/kg·K)
  final double sg;   // Entropía vapor saturado (kJ/kg·K)

  PuntoSaturacion({
    required this.t,
    required this.pSat,
    required this.vf,
    required this.vg,
    required this.uf,
    required this.ug,
    required this.hf,
    required this.hg,
    required this.sf,
    required this.sg,
  });

  // Constructor Factory para transformar el formato JSON/Map de agua_saturacion.txt
  factory PuntoSaturacion.fromMap(Map<String, dynamic> map) {
    return PuntoSaturacion(
      t: (map['T'] as num).toDouble(),
      pSat: (map['Psat'] as num).toDouble(),
      vf: (map['vf'] as num).toDouble(),
      vg: (map['vg'] as num).toDouble(),
      uf: (map['uf'] as num).toDouble(),
      ug: (map['ug'] as num).toDouble(),
      hf: (map['hf'] as num).toDouble(),
      hg: (map['hg'] as num).toDouble(),
      sf: (map['sf'] as num).toDouble(),
      sg: (map['sg'] as num).toDouble(),
    );
  }
}