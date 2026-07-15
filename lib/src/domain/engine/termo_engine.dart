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
  // Tolerancia para comparaciones de punto flotante
  static const double _epsilon = 1e-7;

  TermoEngine({required this.db});

  // ====================================================================
  // 1. MÓDULOS DE INTERPOLACIÓN MATEMÁTICA BÁSICA
  // ====================================================================

  /// Ejecuta la fórmula matemática de interpolación lineal simple.
  double _interpolarLineal(
      double xUser,
      double x1,
      double x2,
      double y1,
      double y2,
      ) {
    if ((x1 - x2).abs() < 1e-14) return y1; 
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
  PuntoSaturacion _buscarPropiedadesSaturacionPorT(double tUser) {
    final tabla = db.tablaSaturacion;

    if (tUser < tabla.first.t - _epsilon) {
      throw Exception("Temperatura por debajo del límite de las tablas.");
    }
    if (tUser > tabla.last.t + _epsilon) {
      throw Exception("Temperatura por encima del límite (Punto Crítico).");
    }

    // Búsqueda exacta con tolerancia
    for (var punto in tabla) {
      if (_sonIguales(punto.t, tUser, epsilon: _epsilon)) return punto;
    }

    PuntoSaturacion? p1;
    PuntoSaturacion? p2;

    for (int i = 0; i < tabla.length - 1; i++) {
      if (tabla[i].t <= tUser && tabla[i + 1].t >= tUser) {
        p1 = tabla[i];
        p2 = tabla[i + 1];
        break;
      }
    }

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
  PuntoSaturacion _buscarPropiedadesSaturacionPorP(double pUser) {
    final tabla = db.tablaSaturacion;

    if (pUser < tabla.first.pSat - _epsilon) {
      throw Exception("Presión por debajo del límite de las tablas.");
    }
    if (pUser > tabla.last.pSat + _epsilon) {
      throw Exception("Presión por encima del límite (Punto Crítico).");
    }

    for (var punto in tabla) {
      if (_sonIguales(punto.pSat, pUser, epsilon: _epsilon)) return punto;
    }

    PuntoSaturacion? p1, p2;
    for (int i = 0; i < tabla.length - 1; i++) {
      if (tabla[i].pSat <= pUser && tabla[i + 1].pSat >= pUser) {
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

    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      if (_sonIguales(db.tablaSobrecalentado[i].p, pUser, epsilon: _epsilon)) {
        b1 = b2 = db.tablaSobrecalentado[i];
        break;
      }
      if (db.tablaSobrecalentado[i].p < pUser &&
          db.tablaSobrecalentado[i + 1].p > pUser) {
        b1 = db.tablaSobrecalentado[i];
        b2 = db.tablaSobrecalentado[i + 1];
        break;
      }
    }
    
    // Verificación final del último elemento
    if (b1 == null && _sonIguales(db.tablaSobrecalentado.last.p, pUser, epsilon: _epsilon)) {
      b1 = b2 = db.tablaSobrecalentado.last;
    }

    if (b1 == null || b2 == null) {
      throw Exception("Propiedades de sobrecalentado no disponibles para esta presión.");
    }

    var prop1 = _obtenerPropiedadesEnBloquePorT(b1, tUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloquePorT(b2, tUser);

    return EstadoTermodinamico(
      fase: "Vapor Sobrecalentado",
      p: pUser,
      t: tUser,
      v: _interpolarLineal(pUser, b1.p, b2.p, prop1.v, prop2.v),
      u: _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u),
      h: _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h),
      s: _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s),
    );
  }

  /// Busca propiedades a una Temperatura específica dentro de un bloque de presión constante.
  PropiedadSobrecalentada _obtenerPropiedadesEnBloquePorT(
      BloquePresionSobrecalentado bloque,
      double tUser,
      ) {
    final props = bloque.propiedadesPorT;

    if (tUser < bloque.tSat - _epsilon) {
      throw Exception("A ${bloque.p} kPa, la temperatura $tUser°C está en zona de saturación.");
    }
    if (tUser > props.last.t + _epsilon) {
      throw Exception("Temperatura fuera del rango superior ($tUser > ${props.last.t}).");
    }

    for (var p in props) {
      if (_sonIguales(p.t, tUser, epsilon: _epsilon)) return p;
    }

    for (int i = 0; i < props.length - 1; i++) {
      if (props[i].t <= tUser && props[i + 1].t >= tUser) {
        return PropiedadSobrecalentada(
          t: tUser,
          v: _interpolarLineal(tUser, props[i].t, props[i + 1].t, props[i].v, props[i + 1].v),
          u: _interpolarLineal(tUser, props[i].t, props[i + 1].t, props[i].u, props[i + 1].u),
          h: _interpolarLineal(tUser, props[i].t, props[i + 1].t, props[i].h, props[i + 1].h),
          s: _interpolarLineal(tUser, props[i].t, props[i + 1].t, props[i].s, props[i + 1].s),
        );
      }
    }
    throw Exception("Error de interpolación de temperatura.");
  }

  /// Resuelve la interpolación doble para la zona de vapor sobrecalentado dado T y v.
  EstadoTermodinamico _resolverSobrecalentadoTyV(double tUser, double vUser) {
    BloquePresionSobrecalentado? b1, b2;
    PropiedadSobrecalentada? prop1, prop2;

    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      var bloqueA = db.tablaSobrecalentado[i];
      var bloqueB = db.tablaSobrecalentado[i + 1];

      // Si la T es menor a Tsat en ambos, este intervalo no nos sirve
      if (tUser < bloqueA.tSat - _epsilon && tUser < bloqueB.tSat - _epsilon) continue;

      // Obtener propiedades virtuales. Si la T es menor a Tsat del bloque, usamos vapor saturado del bloque.
      PropiedadSobrecalentada pV1;
      if (tUser < bloqueA.tSat - _epsilon) {
          // Si T_user < T_sat del bloque, a esa presión NO es sobrecalentado.
          // Pero para interpolar, necesitamos saber dónde termina el sobrecalentado (línea de saturación).
          // Sin embargo, si tUser es menor a Tsat de AMBOS bloques, el punto no es sobrecalentado.
          continue; 
      } else {
          pV1 = _obtenerPropiedadesEnBloquePorT(bloqueA, tUser);
      }

      PropiedadSobrecalentada pV2;
      double p2Coord = bloqueB.p;
      if (tUser < bloqueB.tSat - _epsilon) {
          // El bloque B está "dentro" de la campana para esta T. 
          // Usamos el punto de vapor saturado (vg) a tUser como límite derecho de la interpolación.
          PuntoSaturacion satAtT = _buscarPropiedadesSaturacionPorT(tUser);
          pV2 = PropiedadSobrecalentada(t: tUser, v: satAtT.vg, u: satAtT.ug, h: satAtT.hg, s: satAtT.sg);
          p2Coord = satAtT.pSat;
      } else {
          pV2 = _obtenerPropiedadesEnBloquePorT(bloqueB, tUser);
      }

      // vUser debe estar entre pV1.v y pV2.v (v disminuye al aumentar P)
      if (vUser <= pV1.v + _epsilon && vUser >= pV2.v - _epsilon) {
        b1 = bloqueA;
        prop1 = pV1;
        prop2 = pV2;
        // La presión b2 es p2Coord (que podría ser pSat o la P del bloque)
        return EstadoTermodinamico(
          fase: "Vapor Sobrecalentado",
          p: _interpolarLineal(vUser, prop1.v, prop2.v, b1.p, p2Coord),
          t: tUser, v: vUser,
          u: _interpolarLineal(vUser, prop1.v, prop2.v, prop1.u, prop2.u),
          h: _interpolarLineal(vUser, prop1.v, prop2.v, prop1.h, prop2.h),
          s: _interpolarLineal(vUser, prop1.v, prop2.v, prop1.s, prop2.s),
        );
      }
    }

    throw Exception("El volumen ingresado está fuera de los límites de sobrecalentado.");
  }

  // ====================================================================
  // 3. MÓDULOS DE DECISIÓN PRINCIPALES (Los "If" de tu Diagrama de Flujo)
  // ====================================================================

  /// Módulo de entrada principal: Temperatura y Volumen Específico (Caso T-v)
  EstadoTermodinamico resolverEstadoPorTyV(double tUser, double vUser) {
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorT(tUser);

    if (vUser < limitesSat.vf - _epsilon) {
      // ESTADO: LÍQUIDO COMPRIMIDO (Aproximación saturada a T_user)
      return EstadoTermodinamico(
        fase: "Líquido Comprimido", p: limitesSat.pSat, t: tUser,
        v: limitesSat.vf, u: limitesSat.uf, h: limitesSat.hf, s: limitesSat.sf,
      );
    } else if (vUser <= limitesSat.vg + _epsilon) {
      // ESTADO: MEZCLA HÚMEDA
      double x = (vUser - limitesSat.vf) / (limitesSat.vg - limitesSat.vf);
      if (x < 0) x = 0; if (x > 1) x = 1;
      return EstadoTermodinamico(
        fase: "Mezcla Húmeda", p: limitesSat.pSat, t: tUser, v: vUser, x: x,
        u: limitesSat.uf + x * (limitesSat.ug - limitesSat.uf),
        h: limitesSat.hf + x * (limitesSat.hg - limitesSat.hf),
        s: limitesSat.sf + x * (limitesSat.sg - limitesSat.sf),
      );
    } else {
      // ESTADO: VAPOR SOBRECALENTADO
      return _resolverSobrecalentadoTyV(tUser, vUser);
    }
  }

  /// Módulo de entrada principal: Presión y Volumen específico (Caso P-v)
  EstadoTermodinamico resolverEstadoPorPv(double pUser, double vUser) {
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorP(pUser);

    if (vUser < limitesSat.vf - _epsilon) {
      // ESTADO: LÍQUIDO COMPRIMIDO (Aproximación saturada a P_user)
      return EstadoTermodinamico(
        fase: "Líquido Comprimido", p: pUser, t: limitesSat.t,
        v: limitesSat.vf, u: limitesSat.uf, h: limitesSat.hf, s: limitesSat.sf,
      );
    } else if (vUser <= limitesSat.vg + _epsilon) {
      // ESTADO: MEZCLA HÚMEDA
      double x = (vUser - limitesSat.vf) / (limitesSat.vg - limitesSat.vf);
      if (x < 0) x = 0; if (x > 1) x = 1;
      return EstadoTermodinamico(
        fase: "Mezcla Húmeda", p: pUser, t: limitesSat.t, v: vUser, x: x,
        u: limitesSat.uf + x * (limitesSat.ug - limitesSat.uf),
        h: limitesSat.hf + x * (limitesSat.hg - limitesSat.hf),
        s: limitesSat.sf + x * (limitesSat.sg - limitesSat.sf),
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
      if (_sonIguales(db.tablaSobrecalentado[i].p, pUser, epsilon: _epsilon)) {
        b1 = b2 = db.tablaSobrecalentado[i];
        break;
      }
      if (db.tablaSobrecalentado[i].p < pUser && db.tablaSobrecalentado[i + 1].p > pUser) {
        b1 = db.tablaSobrecalentado[i];
        b2 = db.tablaSobrecalentado[i + 1];
        break;
      }
    }
    
    if (b1 == null && _sonIguales(db.tablaSobrecalentado.last.p, pUser, epsilon: _epsilon)) {
      b1 = b2 = db.tablaSobrecalentado.last;
    }

    if (b1 == null || b2 == null) throw Exception("Presión fuera de rango.");

    var prop1 = _obtenerPropiedadesEnBloquePorV(b1, vUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloquePorV(b2, vUser);

    return EstadoTermodinamico(
      fase: "Vapor Sobrecalentado", p: pUser,
      t: _interpolarLineal(pUser, b1.p, b2.p, prop1.t, prop2.t),
      v: vUser,
      u: _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u),
      h: _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h),
      s: _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s),
    );
  }

  /// Busca propiedades a un Volumen específico dentro de un bloque de presión constante.
  PropiedadSobrecalentada _obtenerPropiedadesEnBloquePorV(
      BloquePresionSobrecalentado bloque,
      double vUser,
      ) {
    final props = bloque.propiedadesPorT;

    if (vUser > props.last.v + _epsilon) {
      throw Exception("Volumen fuera del rango superior del bloque.");
    }
    
    // Si vUser es menor al primer v del bloque (vapor saturado), usamos ese como límite
    if (vUser < props.first.v - _epsilon) {
        PuntoSaturacion sat = _buscarPropiedadesSaturacionPorP(bloque.p);
        return PropiedadSobrecalentada(t: bloque.tSat, v: sat.vg, u: sat.ug, h: sat.hg, s: sat.sg);
    }

    for (var p in props) if (_sonIguales(p.v, vUser, epsilon: _epsilon)) return p;

    for (int i = 0; i < props.length - 1; i++) {
      if (props[i].v >= vUser && props[i + 1].v <= vUser) { // v disminuye al aumentar T en sobrecalentado? No, v aumenta al aumentar T a P constante.
        // ERROR LOGICO: A P constante, el volumen AUMENTA con la Temperatura.
        // Corregimos la comparación:
      }
    }
    
    // Re-escritura correcta de búsqueda por volumen a P constante:
    for (int i = 0; i < props.length - 1; i++) {
        if (props[i].v <= vUser && props[i+1].v >= vUser) {
            return PropiedadSobrecalentada(
                t: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].t, props[i+1].t),
                v: vUser,
                u: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].u, props[i+1].u),
                h: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].h, props[i+1].h),
                s: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].s, props[i+1].s),
            );
        }
    }
    
    throw Exception("Error de interpolación de volumen.");
  }

  /// Módulo de entrada principal: Presión y Temperatura (Caso P-T)
  EstadoTermodinamico resolverEstadoPorPyT(double pUser, double tUser) {
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorP(pUser);
    const double tolerancia = 0.01; // Tolerancia en °C

    if (tUser < (limitesSat.t - tolerancia)) {
      // ESTADO: LÍQUIDO COMPRIMIDO
      PuntoSaturacion propsLiquido = _buscarPropiedadesSaturacionPorT(tUser);
      return EstadoTermodinamico(
        fase: "Líquido Comprimido", p: pUser, t: tUser,
        v: propsLiquido.vf, u: propsLiquido.uf, h: propsLiquido.hf, s: propsLiquido.sf,
      );
    } else if (tUser > (limitesSat.t + tolerancia)) {
      // ESTADO: VAPOR SOBRECALENTADO
      return _resolverSobrecalentadoPyT(pUser, tUser);
    } else {
      throw Exception("Estado Indeterminado (Saturación). Ingrese calidad (x) o volumen (v).");
    }
  }
}
