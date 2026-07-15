import os
import json
import numpy as np

try:
    import CoolProp.CoolProp as CP  # type: ignore
except ImportError:
    try:
        import CoolProp as CP  # type: ignore
    except ImportError as e:
        raise ImportError(
            "CoolProp no está instalado o no está accesible en el intérprete actual. "
            "Instálelo con 'pip install CoolProp' y ejecútelo con el mismo Python."
        ) from e
import CoolProp.CoolProp as CP
fluido = "Ammonia"

script_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.abspath(os.path.join(script_dir, '..', 'assets'))
if not os.path.exists(assets_dir):
    os.makedirs(assets_dir)

output_path = os.path.join(assets_dir, 'amoniaco_sobrecalentado.json')

# 1. Lista de presiones para Amoníaco (en kPa)
# Adaptado para rangos comunes de Amoníaco
presiones_kpa = np.array([
    20.0, 50.0, 100.0, 200.0, 300.0, 400.0, 500.0, 600.0, 800.0, 1000.0,
    1200.0, 1400.0, 1600.0, 1800.0, 2000.0, 2500.0, 3000.0, 4000.0, 5000.0
], dtype=np.float64)

# 2. Barrido de temperaturas fijas (°C)
temperaturas_fijas_c = np.array([
    -40.0, -30.0, -20.0, -10.0, 0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0,
    80.0, 100.0, 120.0, 140.0, 160.0, 180.0, 200.0, 220.0, 240.0, 260.0
], dtype=np.float64)

bloques_sobrecalentado = []

print(f"Iniciando la extracción masiva para {fluido}...")

for p_kpa in presiones_kpa:
    p_pa = float(p_kpa * 1000.0)

    try:
        # Definir los límites lógicos de la campana
        t_sat_k = float(CP.PropsSI("T", "P", p_pa, "Q", 1, fluido))
        t_sat_c = float(np.round(t_sat_k - 273.15, 2))

        bloque_actual = {
            "P": float(p_kpa),
            "T_sat": t_sat_c,
            "propiedades_por_T": []
        }
        
        # --- FILA 1: Vapor Saturado en T_sat ---
        v_sat_g = 1.0 / CP.PropsSI("D", "P", p_pa, "Q", 1, fluido)
        u_sat_g = CP.PropsSI("U", "P", p_pa, "Q", 1, fluido) / 1000.0
        h_sat_g = CP.PropsSI("H", "P", p_pa, "Q", 1, fluido) / 1000.0
        s_sat_g = CP.PropsSI("S", "P", p_pa, "Q", 1, fluido) / 1000.0
        
        bloque_actual["propiedades_por_T"].append({
            "T": t_sat_c,
            "v": float(np.round(v_sat_g, 8)),
            "u": float(np.round(u_sat_g, 4)),
            "h": float(np.round(h_sat_g, 4)),
            "s": float(np.round(s_sat_g, 6))
        })

        # --- FILAS SIGUIENTES: Temperaturas sobrecalentadas ---
        temperaturas_validas = temperaturas_fijas_c[temperaturas_fijas_c > t_sat_c + 0.01]
        for t_c in temperaturas_validas:
            t_k = float(t_c + 273.15)

            try:
                # CORRECCIÓN: Usar Densidad (D) para calcular volumen específico (1/D)
                # CP.PropsSI("V", ...) devuelve viscosidad dinámica, NO volumen específico.
                v = 1.0 / float(CP.PropsSI("D", "P", p_pa, "T", t_k, fluido))
                u = float(CP.PropsSI("U", "P", p_pa, "T", t_k, fluido) / 1000.0)
                h = float(CP.PropsSI("H", "P", p_pa, "T", t_k, fluido) / 1000.0)
                s = float(CP.PropsSI("S", "P", p_pa, "T", t_k, fluido) / 1000.0)

                bloque_actual["propiedades_por_T"].append({
                    "T": float(t_c),
                    "v": float(np.round(v, 8)),
                    "u": float(np.round(u, 4)),
                    "h": float(np.round(h, 4)),
                    "s": float(np.round(s, 6))
                })
            except Exception:
                continue
                    
        bloques_sobrecalentado.append(bloque_actual)
        print(f" -> Bloque P = {p_kpa} kPa procesado. Filas: {len(bloque_actual['propiedades_por_T'])}")
        
    except Exception as e:
        print(f"Error en {p_kpa} kPa: {e}")

# 3. Escritura del JSON resultante
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(bloques_sobrecalentado, f, indent=2, ensure_ascii=False)

print(f"\n¡Extracción masiva completada! Archivo: '{output_path}'")
