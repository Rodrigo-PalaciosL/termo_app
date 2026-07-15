// import 'dart:math';
import '../../data/models/saturacion_model.dart';
import '../../data/models/sobrecalentado_model.dart';
import '../../data/models/termo_database.dart';

// --- CLASE AUXILIAR PARA RETORNAR LOS RESULTADOS ---
// Esto empaqueta todas las respuestas que el motor calcule para enviarlas a la interfaz.
class EstadoTermodinamico {
  final String
  fase; // "Líquido Comprimido", "Mezcla Húmeda", "Vapor Sobrecalentado", etc.
  final double p; // kPa
  final double t; // °C
  final double v; // m³/kg
  final double u; // kJ/kg
  final double h; // kJ/kg
  final double s; // kJ/kg·K
  final double? x; // Calidad (nula si no es mezcla húmeda)

  EstadoTermodinamico({
    required this.fase,
    required this.p,
    required this.t,
    required this.v,
    required this.u,
    required this.h,
    required this.s,
    this.x,
  });
}

class TermoEngine {
  final TermoDatabase db;

  TermoEngine({required this.db});

  // ====================================================================
  // 1. MÓDULOS DE INTERPOLACIÓN MATEMÁTICA BÁSICA
  // ====================================================================

  /// Ejecuta la fórmula matemática de interpolación lineal simple.
  /// Retorna el valor Y correspondiente a un valor X de entrada, dado un rango [x1, x2] y [y1, y2].
  double _interpolarLineal(
    double xUser,
    double x1,
    double x2,
    double y1,
    double y2,
  ) {
    if ((x1 - x2).abs() < 1e-12) return y1; // Prevención de división por cero
    double factor = (xUser - x1) / (x2 - x1);
    return y1 + factor * (y2 - y1);
  }

  bool _sonIguales(double a, double b, {double epsilon = 1e-9}) {
    return (a - b).abs() <= epsilon;
  }

  // ====================================================================
  // 2. MÓDULOS DE BÚSQUEDA EN LA BASE DE DATOS
  // ====================================================================

  /// Busca una temperatura específica en la tabla de saturación.
  /// Si no existe exacta, interpola todas las propiedades del renglón.
  PuntoSaturacion _buscarPropiedadesSaturacionPorT(double tUser) {
    final tabla = db.tablaSaturacion;

    // Validación de límites: Fuera de rango (Sólido/Hielo o Régimen Supercrítico)
    if (tUser < tabla.first.t) {
      throw Exception("Temperatura por debajo del punto triple.");
    }
    if (tUser > tabla.last.t) {
      throw Exception("Temperatura en la zona hipercrítica (mayor a T_crit).");
    }

    // Búsqueda exacta
    for (var punto in tabla) {
      if (_sonIguales(punto.t, tUser)) return punto;
    }

    // Si no es exacta, buscamos los límites para interpolar
    PuntoSaturacion? p1;
    PuntoSaturacion? p2;

    for (int i = 0; i < tabla.length - 1; i++) {
      if (tabla[i].t < tUser && tabla[i + 1].t > tUser) {
        p1 = tabla[i];
        p2 = tabla[i + 1];
        break;
      }
    }

    // Interpolamos el renglón completo de propiedades para esa T_user
    return PuntoSaturacion(
      t: tUser,
      pSat: _interpolarLineal(tUser, p1!.t, p2!.t, p1.pSat, p2.pSat),
      vf: _interpolarLineal(tUser, p1.t, p2.t, p1.vf, p2.vf),
      vg: _interpolarLineal(tUser, p1.t, p2.t, p1.vg, p2.vg),
      uf: _interpolarLineal(tUser, p1.t, p2.t, p1.uf, p2.uf),
      ug: _interpolarLineal(tUser, p1.t, p2.t, p1.ug, p2.ug),
      hf: _interpolarLineal(tUser, p1.t, p2.t, p1.hf, p2.hf),
      hg: _interpolarLineal(tUser, p1.t, p2.t, p1.hg, p2.hg),
      sf: _interpolarLineal(tUser, p1.t, p2.t, p1.sf, p2.sf),
      sg: _interpolarLineal(tUser, p1.t, p2.t, p1.sg, p2.sg),
    );
  }

  /// Busca una presión específica en la tabla de saturación.
  /// Si no existe exacta, interpola todas las propiedades del renglón.
  PuntoSaturacion _buscarPropiedadesSaturacionPorP(double pUser) {
    final tabla = db.tablaSaturacion;

    if (pUser < tabla.first.pSat) {
      throw Exception("Presión por debajo del punto triple.");
    }
    if (pUser > tabla.last.pSat) {
      throw Exception("Presión hipercrítica. Fuera de tabla de saturación.");
    }

    // Búsqueda exacta
    for (var punto in tabla) {
      if (_sonIguales(punto.pSat, pUser)) return punto;
    }

    // Interpolación de la fila completa si la presión cae en el medio
    PuntoSaturacion? p1, p2;
    for (int i = 0; i < tabla.length - 1; i++) {
      if (tabla[i].pSat < pUser && tabla[i + 1].pSat > pUser) {
        p1 = tabla[i];
        p2 = tabla[i + 1];
        break;
      }
    }

    return PuntoSaturacion(
      t: _interpolarLineal(pUser, p1!.pSat, p2!.pSat, p1.t, p2.t),
      pSat: pUser,
      vf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.vf, p2.vf),
      vg: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.vg, p2.vg),
      uf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.uf, p2.uf),
      ug: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.ug, p2.ug),
      hf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.hf, p2.hf),
      hg: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.hg, p2.hg),
      sf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.sf, p2.sf),
      sg: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.sg, p2.sg),
    );
  }

  /// Resuelve la interpolación doble para la zona de vapor sobrecalentado dado P y T.
  EstadoTermodinamico _resolverSobrecalentadoPyT(double pUser, double tUser) {
    BloquePresionSobrecalentado? b1, b2;

    // 1. Encontrar los bloques de presión que encierran a P_user
    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      if (db.tablaSobrecalentado[i].p == pUser) {
        b1 = db.tablaSobrecalentado[i];
        b2 = b1; // Es exacta, no hay necesidad de cruzar presiones
        break;
      }
      if (db.tablaSobrecalentado[i].p < pUser &&
          db.tablaSobrecalentado[i + 1].p > pUser) {
        b1 = db.tablaSobrecalentado[i];
        b2 = db.tablaSobrecalentado[i + 1];
        break;
      }
    }

    if (b1 == null || b2 == null) {
      throw Exception(
        "La presión ingresada está fuera de las tablas de sobrecalentado.",
      );
    }

    // 2. Obtener Estados Virtuales a la Temperatura del usuario en ambos bloques
    var prop1 = _obtenerPropiedadesEnBloquePorT(b1, tUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloquePorT(b2, tUser);

    // 3. Interpolación Cruzada Final (Usando la presión como X)
    double vFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.v, prop2.v);
    double uFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u);
    double hFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h);
    double sFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s);

    return EstadoTermodinamico(
      fase: "Vapor Sobrecalentado",
      p: pUser,
      t: tUser,
      v: vFinal,
      u: uFinal,
      h: hFinal,
      s: sFinal,
    );
  }

  /// Busca propiedades a una Temperatura específica dentro de un bloque de presión constante.
  /// Si la T no es exacta, interpola linealmente entre las filas del bloque.
  PropiedadSobrecalentada _obtenerPropiedadesEnBloquePorT(
    BloquePresionSobrecalentado bloque,
    double tUser,
  ) {
    final props = bloque.propiedadesPorT;

    // Validación de límites para el bloque
    if (tUser < bloque.tSat) {
      throw Exception(
        "Temperatura por debajo de Tsat (${bloque.tSat}°C) para la presión de ${bloque.p} kPa.",
      );
    }
    if (tUser > props.last.t) {
      throw Exception(
        "Temperatura fuera del rango superior del bloque de ${bloque.p} kPa.",
      );
    }

    // Búsqueda exacta
    for (var p in props) {
      if (p.t == tUser) return p;
    }

    // Interpolación si cae entre dos filas
    for (int i = 0; i < props.length - 1; i++) {
      if (props[i].t < tUser && props[i + 1].t > tUser) {
        var p1 = props[i];
        var p2 = props[i + 1];

        return PropiedadSobrecalentada(
          t: tUser,
          v: _interpolarLineal(tUser, p1.t, p2.t, p1.v, p2.v),
          u: _interpolarLineal(tUser, p1.t, p2.t, p1.u, p2.u),
          h: _interpolarLineal(tUser, p1.t, p2.t, p1.h, p2.h),
          s: _interpolarLineal(tUser, p1.t, p2.t, p1.s, p2.s),
        );
      }
    }
    throw Exception("Error de algoritmo al interpolar temperatura en bloque.");
  }

  /// Resuelve la interpolación doble para la zona de vapor sobrecalentado dado T y v.
  EstadoTermodinamico _resolverSobrecalentadoTyV(double tUser, double vUser) {
    BloquePresionSobrecalentado? b1, b2;
    PropiedadSobrecalentada? prop1, prop2;

    // Recorremos los bloques de presión buscando dónde se encierra el volumen
    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      var bloqueActual = db.tablaSobrecalentado[i];
      var bloqueSiguiente = db.tablaSobrecalentado[i + 1];

      // Si la temperatura ingresada es menor a la de saturación de estos bloques,
      // significa que a esa presión el gas ya se habría condensado. Saltamos.
      if (tUser < bloqueActual.tSat || tUser < bloqueSiguiente.tSat) continue;

      // Obtenemos los "Estados Virtuales" a T_user para ambas presiones
      var pVirtual1 = _obtenerPropiedadesEnBloquePorT(bloqueActual, tUser);
      var pVirtual2 = _obtenerPropiedadesEnBloquePorT(bloqueSiguiente, tUser);

      // Como P aumenta, el volumen disminuye. El vUser debe estar en medio.
      if (vUser <= pVirtual1.v && vUser >= pVirtual2.v) {
        b1 = bloqueActual;
        b2 = bloqueSiguiente;
        prop1 = pVirtual1;
        prop2 = pVirtual2;
        break;
      }
    }

    if (b1 == null || b2 == null) {
      throw Exception(
        "El volumen ingresado está fuera de las tablas de sobrecalentado disponibles.",
      );
    }

    // INTERPOLACIÓN CRUZADA FINAL (Usando el volumen como el valor X conocido)
    double pFinal = _interpolarLineal(vUser, prop1!.v, prop2!.v, b1.p, b2.p);
    double uFinal = _interpolarLineal(
      vUser,
      prop1.v,
      prop2.v,
      prop1.u,
      prop2.u,
    );
    double hFinal = _interpolarLineal(
      vUser,
      prop1.v,
      prop2.v,
      prop1.h,
      prop2.h,
    );
    double sFinal = _interpolarLineal(
      vUser,
      prop1.v,
      prop2.v,
      prop1.s,
      prop2.s,
    );

    return EstadoTermodinamico(
      fase: "Vapor Sobrecalentado",
      p: pFinal,
      t: tUser,
      v: vUser,
      u: uFinal,
      h: hFinal,
      s: sFinal,
    );
  }

  // ====================================================================
  // 3. MÓDULOS DE DECISIÓN PRINCIPALES (Los "If" de tu Diagrama de Flujo)
  // ====================================================================

  /// Módulo de entrada principal: Temperatura y Volumen Específico (Caso T-v)
  EstadoTermodinamico resolverEstadoPorTyV(double tUser, double vUser) {
    // 1. Ubicación en Tabla de Saturación
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorT(tUser);

    // 2. Filtro de Comparación de Regiones (Como definimos en la Lógica)
    if (vUser < limitesSat.vf) {
      // ESTADO: LÍQUIDO COMPRIMIDO
      // Aplicamos la aproximación de ingeniería: v, u, h, s dependen casi 100% de T (usamos valores 'f')
      return EstadoTermodinamico(
        fase: "Líquido Comprimido",
        p: limitesSat
            .pSat, // La presión es al menos la de saturación (para fines de la vista gráfica)
        t: tUser,
        v: limitesSat.vf,
        u: limitesSat.uf,
        h: limitesSat.hf,
        s: limitesSat.sf,
      );
    } else if (vUser >= limitesSat.vf && vUser <= limitesSat.vg) {
      // ESTADO: MEZCLA HÚMEDA
      // Calculamos la calidad 'x'
      double x = (vUser - limitesSat.vf) / (limitesSat.vg - limitesSat.vf);

      // Calculamos propiedades finales en mezcla: Y_final = Y_f + x * (Y_g - Y_f)
      double uFinal = limitesSat.uf + x * (limitesSat.ug - limitesSat.uf);
      double hFinal = limitesSat.hf + x * (limitesSat.hg - limitesSat.hf);
      double sFinal = limitesSat.sf + x * (limitesSat.sg - limitesSat.sf);

      return EstadoTermodinamico(
        fase: "Mezcla Húmeda",
        p: limitesSat.pSat,
        t: tUser,
        v: vUser,
        u: uFinal,
        h: hFinal,
        s: sFinal,
        x: x,
      );
    } else {
      // ESTADO: VAPOR SOBRECALENTADO
      return _resolverSobrecalentadoTyV(tUser, vUser);
    }
  }

  /// Módulo de entrada principal: Presión y Volumen específico (Caso P-v)
  EstadoTermodinamico resolverEstadoPorPv(double pUser, double vUser) {
    // 1. Obtener límites de saturación a esta Presión
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorP(pUser);

    // 2. Filtro de Regiones
    if (vUser < limitesSat.vf) {
      // ESTADO: LÍQUIDO COMPRIMIDO
      return EstadoTermodinamico(
        fase: "Líquido Comprimido",
        p: pUser,
        t: limitesSat.t, // Aproximación grosera si no hay tablas de liq. comp.
        v: limitesSat.vf,
        u: limitesSat.uf,
        h: limitesSat.hf,
        s: limitesSat.sf,
      );
    } else if (vUser >= limitesSat.vf && vUser <= limitesSat.vg) {
      // ESTADO: MEZCLA HÚMEDA
      double x = (vUser - limitesSat.vf) / (limitesSat.vg - limitesSat.vf);

      double uFinal = limitesSat.uf + x * (limitesSat.ug - limitesSat.uf);
      double hFinal = limitesSat.hf + x * (limitesSat.hg - limitesSat.hf);
      double sFinal = limitesSat.sf + x * (limitesSat.sg - limitesSat.sf);

      return EstadoTermodinamico(
        fase: "Mezcla Húmeda",
        p: pUser,
        t: limitesSat.t,
        v: vUser,
        u: uFinal,
        h: hFinal,
        s: sFinal,
        x: x,
      );
    } else {
      // ESTADO: VAPOR SOBRECALENTADO
      return _resolverSobrecalentadoPv(pUser, vUser);
    }
  }

  /// Resuelve la interpolación doble para vapor sobrecalentado dado P y v.
  EstadoTermodinamico _resolverSobrecalentadoPv(double pUser, double vUser) {
    BloquePresionSobrecalentado? b1, b2;

    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      if (db.tablaSobrecalentado[i].p == pUser) {
        b1 = db.tablaSobrecalentado[i];
        b2 = b1;
        break;
      }
      if (db.tablaSobrecalentado[i].p < pUser &&
          db.tablaSobrecalentado[i + 1].p > pUser) {
        b1 = db.tablaSobrecalentado[i];
        b2 = db.tablaSobrecalentado[i + 1];
        break;
      }
    }

    if (b1 == null || b2 == null) {
      throw Exception("Presión fuera de rango en tablas de sobrecalentado.");
    }

    var prop1 = _obtenerPropiedadesEnBloquePorV(b1, vUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloquePorV(b2, vUser);

    // Interpolación cruzada por Presión
    double tFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.t, prop2.t);
    double uFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u);
    double hFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h);
    double sFinal = _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s);

    return EstadoTermodinamico(
      fase: "Vapor Sobrecalentado",
      p: pUser,
      t: tFinal,
      v: vUser,
      u: uFinal,
      h: hFinal,
      s: sFinal,
    );
  }

  /// Busca propiedades a un Volumen específico dentro de un bloque de presión constante.
  PropiedadSobrecalentada _obtenerPropiedadesEnBloquePorV(
    BloquePresionSobrecalentado bloque,
    double vUser,
  ) {
    final props = bloque.propiedadesPorT;

    if (vUser < props.first.v) {
      throw Exception(
        "Volumen por debajo del vapor saturado para la presión de ${bloque.p} kPa.",
      );
    }
    if (vUser > props.last.v) {
      throw Exception(
        "Volumen fuera del rango superior en bloque de ${bloque.p} kPa.",
      );
    }

    for (var p in props) {
      if (_sonIguales(p.v, vUser)) return p;
    }

    for (int i = 0; i < props.length - 1; i++) {
      if (props[i].v < vUser && props[i + 1].v > vUser) {
        var p1 = props[i];
        var p2 = props[i + 1];

        return PropiedadSobrecalentada(
          t: _interpolarLineal(vUser, p1.v, p2.v, p1.t, p2.t),
          v: vUser,
          u: _interpolarLineal(vUser, p1.v, p2.v, p1.u, p2.u),
          h: _interpolarLineal(vUser, p1.v, p2.v, p1.h, p2.h),
          s: _interpolarLineal(vUser, p1.v, p2.v, p1.s, p2.s),
        );
      }
    }
    throw Exception("Error de algoritmo al interpolar volumen en bloque.");
  }

  /// Módulo de entrada principal: Presión y Temperatura (Caso P-T)
  EstadoTermodinamico resolverEstadoPorPyT(double pUser, double tUser) {
    // 1. Obtener la Temperatura de Saturación a esta Presión
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorP(pUser);

    // Tolerancia para evitar errores de precisión de punto flotante en Dart
    const double tolerancia = 0.0001;

    // 2. Buscar el bloque de sobrecalentado que corresponde a la presión ingresada
    BloquePresionSobrecalentado? bloqueCorrespondiente;
    for (final bloque in db.tablaSobrecalentado) {
      if (_sonIguales(bloque.p, pUser)) {
        bloqueCorrespondiente = bloque;
        break;
      }
    }

    final double tSatReal = bloqueCorrespondiente?.tSat ?? limitesSat.t;

    // 3. Filtro de Regiones
    if (tUser < (tSatReal - tolerancia)) {
      // ESTADO: LÍQUIDO COMPRIMIDO
      // Como acordamos, la aproximación se hace evaluando el líquido saturado a T_user
      PuntoSaturacion propsLiquido = _buscarPropiedadesSaturacionPorT(tUser);

      return EstadoTermodinamico(
        fase: "Líquido Comprimido",
        p: pUser,
        t: tUser,
        v: propsLiquido.vf,
        u: propsLiquido.uf,
        h: propsLiquido.hf,
        s: propsLiquido.sf,
      );
    } else if (tUser > (tSatReal + tolerancia)) {
      // ESTADO: VAPOR SOBRECALENTADO
      return _resolverSobrecalentadoPyT(pUser, tUser);
    } else {
      // ESTADO: INDETERMINADO (Saturación)
      throw Exception(
        "Estado Indeterminado: A $pUser kPa, la sustancia hierve exactamente a ${tSatReal}°C. "
        "Para definir sus propiedades dentro de la mezcla húmeda, ingresa la Presión con otra variable (v, u, h, s, o calidad x).",
      );
    }
  }
}
