import '../../data/models/liquido_model.dart';
import '../../data/models/saturacion_model.dart';
import '../../data/models/sobrecalentado_model.dart';
import '../../data/models/termo_database.dart';

// --- CLASE AUXILIAR PARA RETORNAR LOS RESULTADOS ---
class EstadoTermodinamico {
  final String fase;
  final double p; // kPa
  final double t; // °C
  final double v; // m³/kg
  final double u; // kJ/kg
  final double h; // kJ/kg
  final double s; // kJ/kg·K
  final double? x; // Calidad (0 a 1)

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
  static const double _epsilon = 1e-7;

  TermoEngine({required this.db});

  // ====================================================================
  // 1. UTILIDADES
  // ====================================================================

  double _interpolarLineal(double xUser, double x1, double x2, double y1, double y2) {
    if ((x1 - x2).abs() < 1e-14) return y1;
    return y1 + (xUser - x1) * (y2 - y1) / (x2 - x1);
  }

  /// Interpolación para gases donde x * y ≈ constante (ej: P * v ≈ constante)
  /// Interpolamos el producto (x * y) linealmente respecto a x, y luego despejamos y.
  double _interpolarGas(double xUser, double x1, double x2, double y1, double y2) {
    if ((x1 - x2).abs() < 1e-14) return y1;
    double c1 = x1 * y1;
    double c2 = x2 * y2;
    double cUser = c1 + (xUser - x1) * (c2 - c1) / (x2 - x1);
    return cUser / xUser;
  }

  bool _sonIguales(double a, double b, {double epsilon = 1e-9}) {
    return (a - b).abs() <= epsilon;
  }

  // ====================================================================
  // 2. BÚSQUEDA SATURACIÓN
  // ====================================================================

  PuntoSaturacion _buscarPropiedadesSaturacionPorT(double tUser) {
    final tabla = db.tablaSaturacion;
    if (tUser < tabla.first.t - _epsilon) throw Exception("Temperatura muy baja para las tablas.");
    if (tUser > tabla.last.t + _epsilon) return tabla.last; // Punto Crítico

    for (var p in tabla) if (_sonIguales(p.t, tUser, epsilon: _epsilon)) return p;

    PuntoSaturacion? p1, p2;
    for (int i = 0; i < tabla.length - 1; i++) {
      if (tabla[i].t <= tUser && tabla[i + 1].t >= tUser) {
        p1 = tabla[i]; p2 = tabla[i + 1]; break;
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

  PuntoSaturacion _buscarPropiedadesSaturacionPorP(double pUser) {
    final tabla = db.tablaSaturacion;
    if (pUser < tabla.first.pSat - _epsilon) throw Exception("Presión muy baja para las tablas.");
    if (pUser > tabla.last.pSat + _epsilon) return tabla.last; // Punto Crítico

    for (var p in tabla) if (_sonIguales(p.pSat, pUser, epsilon: _epsilon)) return p;

    PuntoSaturacion? p1, p2;
    for (int i = 0; i < tabla.length - 1; i++) {
      if (tabla[i].pSat <= pUser && tabla[i + 1].pSat >= pUser) {
        p1 = tabla[i]; p2 = tabla[i + 1]; break;
      }
    }
    return PuntoSaturacion(
      t: _interpolarLineal(pUser, p1!.pSat, p2!.pSat, p1.t, p2.t),
      pSat: pUser,
      vf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.vf, p2.vf),
      vg: _interpolarGas(pUser, p1.pSat, p2.pSat, p1.vg, p2.vg),
      uf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.uf, p2.uf),
      ug: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.ug, p2.ug),
      hf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.hf, p2.hf),
      hg: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.hg, p2.hg),
      sf: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.sf, p2.sf),
      sg: _interpolarLineal(pUser, p1.pSat, p2.pSat, p1.sg, p2.sg),
    );
  }

  // ====================================================================
  // 3. LÓGICA LÍQUIDO COMPRIMIDO
  // ====================================================================

  EstadoTermodinamico _resolverLiquidoPyT(double pUser, double tUser) {
    BloquePresionLiquido? b1, b2;
    for (int i = 0; i < db.tablaLiquido.length - 1; i++) {
      if (_sonIguales(db.tablaLiquido[i].p, pUser, epsilon: _epsilon)) { b1 = b2 = db.tablaLiquido[i]; break; }
      if (db.tablaLiquido[i].p < pUser && db.tablaLiquido[i + 1].p > pUser) { b1 = db.tablaLiquido[i]; b2 = db.tablaLiquido[i + 1]; break; }
    }
    if (b1 == null && _sonIguales(db.tablaLiquido.last.p, pUser, epsilon: _epsilon)) b1 = b2 = db.tablaLiquido.last;
    if (b1 == null || b2 == null) throw Exception("P fuera de rango líquido.");

    var prop1 = _obtenerPropiedadesEnBloqueLiquidoPorT(b1, tUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloqueLiquidoPorT(b2, tUser);

    return EstadoTermodinamico(
      fase: "Líquido Comprimido", p: pUser, t: tUser,
      v: _interpolarLineal(pUser, b1.p, b2.p, prop1.v, prop2.v),
      u: _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u),
      h: _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h),
      s: _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s),
    );
  }

  PropiedadLiquido _obtenerPropiedadesEnBloqueLiquidoPorT(BloquePresionLiquido bloque, double tUser) {
    final props = bloque.propiedadesPorT;
    if (tUser < props.first.t - _epsilon || tUser > props.last.t + _epsilon) throw Exception("T fuera de rango en bloque.");
    for (var p in props) if (_sonIguales(p.t, tUser, epsilon: _epsilon)) return p;
    for (int i = 0; i < props.length - 1; i++) {
      if (props[i].t <= tUser && props[i+1].t >= tUser) {
        return PropiedadLiquido(
          t: tUser,
          v: _interpolarLineal(tUser, props[i].t, props[i+1].t, props[i].v, props[i+1].v),
          u: _interpolarLineal(tUser, props[i].t, props[i+1].t, props[i].u, props[i+1].u),
          h: _interpolarLineal(tUser, props[i].t, props[i+1].t, props[i].h, props[i+1].h),
          s: _interpolarLineal(tUser, props[i].t, props[i+1].t, props[i].s, props[i+1].s),
        );
      }
    }
    throw Exception("Error T en bloque líquido.");
  }

  EstadoTermodinamico _resolverLiquidoTyV(double tUser, double vUser) {
    for (int i = 0; i < db.tablaLiquido.length - 1; i++) {
      try {
        var b1 = db.tablaLiquido[i];
        var b2 = db.tablaLiquido[i + 1];
        var p1 = _obtenerPropiedadesEnBloqueLiquidoPorT(b1, tUser);
        var p2 = _obtenerPropiedadesEnBloqueLiquidoPorT(b2, tUser);
        if (vUser <= p1.v + _epsilon && vUser >= p2.v - _epsilon) {
          return EstadoTermodinamico(
            fase: "Líquido Comprimido", p: _interpolarLineal(vUser, p1.v, p2.v, b1.p, b2.p),
            t: tUser, v: vUser,
            u: _interpolarLineal(vUser, p1.v, p2.v, p1.u, p2.u),
            h: _interpolarLineal(vUser, p1.v, p2.v, p1.h, p2.h),
            s: _interpolarLineal(vUser, p1.v, p2.v, p1.s, p2.s),
          );
        }
      } catch (_) { continue; }
    }
    throw Exception("v de líquido fuera de rango.");
  }

  EstadoTermodinamico _resolverLiquidoPv(double pUser, double vUser) {
    BloquePresionLiquido? b1, b2;
    for (int i = 0; i < db.tablaLiquido.length - 1; i++) {
      if (_sonIguales(db.tablaLiquido[i].p, pUser, epsilon: _epsilon)) { b1 = b2 = db.tablaLiquido[i]; break; }
      if (db.tablaLiquido[i].p < pUser && db.tablaLiquido[i + 1].p > pUser) { b1 = db.tablaLiquido[i]; b2 = db.tablaLiquido[i + 1]; break; }
    }
    if (b1 == null && _sonIguales(db.tablaLiquido.last.p, pUser, epsilon: _epsilon)) b1 = b2 = db.tablaLiquido.last;
    if (b1 == null || b2 == null) throw Exception("P fuera de rango líquido.");

    var prop1 = _obtenerPropiedadesEnBloqueLiquidoPorV(b1, vUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloqueLiquidoPorV(b2, vUser);

    return EstadoTermodinamico(
      fase: "Líquido Comprimido", p: pUser,
      t: _interpolarLineal(pUser, b1.p, b2.p, prop1.t, prop2.t), v: vUser,
      u: _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u),
      h: _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h),
      s: _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s),
    );
  }

  PropiedadLiquido _obtenerPropiedadesEnBloqueLiquidoPorV(BloquePresionLiquido bloque, double vUser) {
    final props = bloque.propiedadesPorT;
    for (int i = 0; i < props.length - 1; i++) {
      if (props[i].v <= vUser && props[i+1].v >= vUser) {
        return PropiedadLiquido(
          t: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].t, props[i+1].t),
          v: vUser,
          u: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].u, props[i+1].u),
          h: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].h, props[i+1].h),
          s: _interpolarLineal(vUser, props[i].v, props[i+1].v, props[i].s, props[i+1].s),
        );
      }
    }
    throw Exception("v fuera de rango en bloque.");
  }

  // ====================================================================
  // 4. LÓGICA VAPOR SOBRECALENTADO
  // ====================================================================

  EstadoTermodinamico _resolverSobrecalentadoPyT(double pUser, double tUser) {
    BloquePresionSobrecalentado? b1, b2;
    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      if (_sonIguales(db.tablaSobrecalentado[i].p, pUser, epsilon: _epsilon)) { b1 = b2 = db.tablaSobrecalentado[i]; break; }
      if (db.tablaSobrecalentado[i].p < pUser && db.tablaSobrecalentado[i + 1].p > pUser) { b1 = db.tablaSobrecalentado[i]; b2 = db.tablaSobrecalentado[i + 1]; break; }
    }
    if (b1 == null && _sonIguales(db.tablaSobrecalentado.last.p, pUser, epsilon: _epsilon)) b1 = b2 = db.tablaSobrecalentado.last;
    if (b1 == null || b2 == null) throw Exception("P fuera de rango sobrecalentado.");

    var prop1 = _obtenerPropiedadesEnBloquePorT(b1, tUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloquePorT(b2, tUser);

    return EstadoTermodinamico(
      fase: "Vapor Sobrecalentado", p: pUser, t: tUser,
      v: _interpolarGas(pUser, b1.p, b2.p, prop1.v, prop2.v),
      u: _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u),
      h: _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h),
      s: _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s),
    );
  }

  PropiedadSobrecalentada _obtenerPropiedadesEnBloquePorT(BloquePresionSobrecalentado bloque, double tUser) {
    final props = bloque.propiedadesPorT;
    if (tUser < bloque.tSat - _epsilon) throw Exception("T en saturación.");
    if (tUser > props.last.t + _epsilon) throw Exception("T fuera de rango.");

    for (var p in props) if (_sonIguales(p.t, tUser, epsilon: _epsilon)) return p;
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
    throw Exception("Error T en sobrecalentado.");
  }

  EstadoTermodinamico _resolverSobrecalentadoTyV(double tUser, double vUser) {
    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      try {
        var bloqueA = db.tablaSobrecalentado[i];
        var bloqueB = db.tablaSobrecalentado[i + 1];
        if (tUser < bloqueA.tSat - 10) continue; // Skip blocks clearly below range

        PropiedadSobrecalentada pV1;
        double p1Coord = bloqueA.p;
        if (tUser < bloqueA.tSat - _epsilon) {
          PuntoSaturacion sat = _buscarPropiedadesSaturacionPorT(tUser);
          pV1 = PropiedadSobrecalentada(t: tUser, v: sat.vg, u: sat.ug, h: sat.hg, s: sat.sg);
          p1Coord = sat.pSat;
        } else { pV1 = _obtenerPropiedadesEnBloquePorT(bloqueA, tUser); }

        PropiedadSobrecalentada pV2;
        double p2Coord = bloqueB.p;
        if (tUser < bloqueB.tSat - _epsilon) {
          PuntoSaturacion sat = _buscarPropiedadesSaturacionPorT(tUser);
          pV2 = PropiedadSobrecalentada(t: tUser, v: sat.vg, u: sat.ug, h: sat.hg, s: sat.sg);
          p2Coord = sat.pSat;
        } else { pV2 = _obtenerPropiedadesEnBloquePorT(bloqueB, tUser); }

        if (vUser <= pV1.v + _epsilon && vUser >= pV2.v - _epsilon) {
          return EstadoTermodinamico(
            fase: "Vapor Sobrecalentado",
            p: _interpolarGas(vUser, pV1.v, pV2.v, p1Coord, p2Coord),
            t: tUser, v: vUser,
            u: _interpolarLineal(vUser, pV1.v, pV2.v, pV1.u, pV2.u),
            h: _interpolarLineal(vUser, pV1.v, pV2.v, pV1.h, pV2.h),
            s: _interpolarLineal(vUser, pV1.v, pV2.v, pV1.s, pV2.s),
          );
        }
      } catch (_) { continue; }
    }
    throw Exception("v fuera de rango sobrecalentado.");
  }

  EstadoTermodinamico _resolverSobrecalentadoPv(double pUser, double vUser) {
    BloquePresionSobrecalentado? b1, b2;
    for (int i = 0; i < db.tablaSobrecalentado.length - 1; i++) {
      if (_sonIguales(db.tablaSobrecalentado[i].p, pUser, epsilon: _epsilon)) { b1 = b2 = db.tablaSobrecalentado[i]; break; }
      if (db.tablaSobrecalentado[i].p < pUser && db.tablaSobrecalentado[i + 1].p > pUser) { b1 = db.tablaSobrecalentado[i]; b2 = db.tablaSobrecalentado[i + 1]; break; }
    }
    if (b1 == null && _sonIguales(db.tablaSobrecalentado.last.p, pUser, epsilon: _epsilon)) b1 = b2 = db.tablaSobrecalentado.last;
    if (b1 == null || b2 == null) throw Exception("P fuera de rango.");

    var prop1 = _obtenerPropiedadesEnBloquePorV(b1, vUser);
    var prop2 = (b1 == b2) ? prop1 : _obtenerPropiedadesEnBloquePorV(b2, vUser);

    return EstadoTermodinamico(
      fase: "Vapor Sobrecalentado", p: pUser,
      t: _interpolarLineal(pUser, b1.p, b2.p, prop1.t, prop2.t), v: vUser,
      u: _interpolarLineal(pUser, b1.p, b2.p, prop1.u, prop2.u),
      h: _interpolarLineal(pUser, b1.p, b2.p, prop1.h, prop2.h),
      s: _interpolarLineal(pUser, b1.p, b2.p, prop1.s, prop2.s),
    );
  }

  PropiedadSobrecalentada _obtenerPropiedadesEnBloquePorV(BloquePresionSobrecalentado bloque, double vUser) {
    final props = bloque.propiedadesPorT;
    if (vUser > props.last.v + _epsilon) throw Exception("v fuera de rango.");
    if (vUser < props.first.v - _epsilon) {
      PuntoSaturacion sat = _buscarPropiedadesSaturacionPorP(bloque.p);
      return PropiedadSobrecalentada(t: bloque.tSat, v: sat.vg, u: sat.ug, h: sat.hg, s: sat.sg);
    }
    for (var p in props) if (_sonIguales(p.v, vUser, epsilon: _epsilon)) return p;
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
    throw Exception("Error v en sobrecalentado.");
  }

  // ====================================================================
  // 5. ENTRADAS PRINCIPALES
  // ====================================================================

  EstadoTermodinamico resolverEstadoPorTyV(double tUser, double vUser) {
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorT(tUser);
    if (vUser < limitesSat.vf - _epsilon) {
      if (db.tablaLiquido.isNotEmpty) {
        try { return _resolverLiquidoTyV(tUser, vUser); } catch (_) {}
      }
      return EstadoTermodinamico(
        fase: "Líquido Comprimido", p: limitesSat.pSat, t: tUser,
        v: vUser, u: limitesSat.uf, h: limitesSat.hf, s: limitesSat.sf,
      );
    } else if (vUser <= limitesSat.vg + _epsilon) {
      double x = (vUser - limitesSat.vf) / (limitesSat.vg - limitesSat.vf);
      if (x < 0) x = 0; if (x > 1) x = 1;
      return EstadoTermodinamico(
        fase: "Mezcla Húmeda", p: limitesSat.pSat, t: tUser, v: vUser, x: x,
        u: limitesSat.uf + x * (limitesSat.ug - limitesSat.uf),
        h: limitesSat.hf + x * (limitesSat.hg - limitesSat.hf),
        s: limitesSat.sf + x * (limitesSat.sg - limitesSat.sf),
      );
    } else {
      return _resolverSobrecalentadoTyV(tUser, vUser);
    }
  }

  EstadoTermodinamico resolverEstadoPorPv(double pUser, double vUser) {
    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorP(pUser);
    if (vUser < limitesSat.vf - _epsilon) {
      if (db.tablaLiquido.isNotEmpty) {
        try { return _resolverLiquidoPv(pUser, vUser); } catch (_) {}
      }
      return EstadoTermodinamico(
        fase: "Líquido Comprimido", p: pUser, t: limitesSat.t,
        v: vUser, u: limitesSat.uf, h: limitesSat.hf, s: limitesSat.sf,
      );
    } else if (vUser <= limitesSat.vg + _epsilon) {
      double x = (vUser - limitesSat.vf) / (limitesSat.vg - limitesSat.vf);
      if (x < 0) x = 0; if (x > 1) x = 1;
      return EstadoTermodinamico(
        fase: "Mezcla Húmeda", p: pUser, t: limitesSat.t, v: vUser, x: x,
        u: limitesSat.uf + x * (limitesSat.ug - limitesSat.uf),
        h: limitesSat.hf + x * (limitesSat.hg - limitesSat.hf),
        s: limitesSat.sf + x * (limitesSat.sg - limitesSat.sf),
      );
    } else {
      return _resolverSobrecalentadoPv(pUser, vUser);
    }
  }

  EstadoTermodinamico resolverEstadoPorPyT(double pUser, double tUser) {
    // Si la presión es supercrítica, intentamos resolver directamente
    if (pUser > db.tablaSaturacion.last.pSat) {
      if (tUser < 132.25 && db.tablaLiquido.isNotEmpty) {
        try { return _resolverLiquidoPyT(pUser, tUser); } catch (_) {}
      }
      return _resolverSobrecalentadoPyT(pUser, tUser);
    }

    PuntoSaturacion limitesSat = _buscarPropiedadesSaturacionPorP(pUser);
    const double tol = 0.01;
    if (tUser < (limitesSat.t - tol)) {
      if (db.tablaLiquido.isNotEmpty) {
        try { return _resolverLiquidoPyT(pUser, tUser); } catch (_) {}
      }
      PuntoSaturacion propsLiquido = _buscarPropiedadesSaturacionPorT(tUser);
      return EstadoTermodinamico(
        fase: "Líquido Comprimido", p: pUser, t: tUser,
        v: propsLiquido.vf, u: propsLiquido.uf, h: propsLiquido.hf, s: propsLiquido.sf,
      );
    } else if (tUser > (limitesSat.t + tol)) {
      return _resolverSobrecalentadoPyT(pUser, tUser);
    } else {
      throw Exception("Saturación. Ingrese calidad (x) o volumen (v).");
    }
  }
}
