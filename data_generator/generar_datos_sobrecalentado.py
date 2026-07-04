import os
import json
import numpy as np
import CoolProp.CoolProp as CP

fluido = "Water"

script_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.abspath(os.path.join(script_dir, '..', 'assets'))
if not os.path.exists(assets_dir):
    os.makedirs(assets_dir)

output_path = os.path.join(assets_dir, 'agua_sobrecalentado.json')

# 1. Lista exhaustiva de presiones de la Tabla A-6 estándar (en kPa)
# Incluye desde presiones ultra bajas (10 kPa) hasta presiones súper altas (60 MPa = 60000 kPa)
presiones_kpa = np.array([
    10.0, 50.0, 100.0, 200.0, 300.0, 400.0, 500.0, 600.0, 800.0, 1000.0,
    1200.0, 1400.0, 1600.0, 1800.0, 2000.0, 2500.0, 3000.0, 3500.0, 4000.0,
    4500.0, 5000.0, 6000.0, 7000.0, 8000.0, 9000.0, 10000.0, 12500.0,
    15000.0, 17500.0, 20000.0, 25000.0, 30000.0, 40000.0, 50000.0, 60000.0
], dtype=np.float64)

# 2. Barrido extendido y completo de temperaturas fijas (°C) de la Tabla A-6
# Se mantiene como array para filtrar los puntos por encima de T_sat de forma simple
temperaturas_fijas_c = np.array([
    50.0, 100.0, 150.0, 200.0, 250.0, 300.0, 350.0, 400.0, 450.0, 500.0,
    550.0, 600.0, 650.0, 700.0, 750.0, 800.0, 900.0, 1000.0, 1100.0, 1200.0, 1300.0
], dtype=np.float64)

bloques_sobrecalentado = []

print("Iniciando la extracción masiva para replicar la Tabla A-6...")

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
        
        # --- FILA 1: El límite inferior exacto (Vapor Saturado en T_sat) ---
        v_sat_g = CP.PropsSI("V", "P", p_pa, "Q", 1, fluido)
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

        # --- FILAS SIGUIENTES: Barrido idéntico a las filas de la Tabla A-6 ---
        temperaturas_validas = temperaturas_fijas_c[temperaturas_fijas_c > t_sat_c]
        for t_c in temperaturas_validas:
            t_k = float(t_c + 273.15)

            try:
                v = float(CP.PropsSI("V", "P", p_pa, "T", t_k, fluido))
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
                # Ignorar si el punto está fuera de los límites físicos estables de CoolProp
                continue
                    
        bloques_sobrecalentado.append(bloque_actual)
        print(f" -> Bloque P = {p_kpa} kPa ({p_kpa/1000 if p_kpa >= 1000 else p_kpa} {'MPa' if p_kpa >= 1000 else 'kPa'}) procesado. Filas: {len(bloque_actual['propiedades_por_T'])}")
        
    except Exception as e:
        # Esto atrapará las presiones por encima del punto crítico (P > 22,064 kPa)
        # En la Tabla A-6, los bloques de 25, 30, 40, 50 y 60 MPa son fluidos supercríticos (no existe T_sat).
        if p_kpa > 22064.0:
            bloque_supercritico = {
                "P": p_kpa,
                "T_sat": None, # No tiene temperatura de saturación por estar arriba del punto crítico
                "propiedades_por_T": []
            }
            
            # Para la región supercrítica de la Tabla A-6 se barren todas las temperaturas directamente
            for t_c in temperaturas_fijas_c:
                t_k = float(t_c + 273.15)
                try:
                    v = float(CP.PropsSI("V", "P", p_pa, "T", t_k, fluido))
                    u = float(CP.PropsSI("U", "P", p_pa, "T", t_k, fluido) / 1000.0)
                    h = float(CP.PropsSI("H", "P", p_pa, "T", t_k, fluido) / 1000.0)
                    s = float(CP.PropsSI("S", "P", p_pa, "T", t_k, fluido) / 1000.0)

                    bloque_supercritico["propiedades_por_T"].append({
                        "T": float(t_c),
                        "v": float(np.round(v, 8)),
                        "u": float(np.round(u, 4)),
                        "h": float(np.round(h, 4)),
                        "s": float(np.round(s, 6))
                    })
                except Exception:
                    continue
            
            if bloque_supercritico["propiedades_por_T"]:
                bloques_sobrecalentado.append(bloque_supercritico)
                print(f" -> Bloque Supercrítico P = {p_kpa} kPa ({p_kpa/1000} MPa) procesado. Filas: {len(bloque_supercritico['propiedades_por_T'])}")
        else:
            print(f"Error inesperado en {p_kpa} kPa: {e}")

# 3. Escritura del JSON resultante
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(bloques_sobrecalentado, f, indent=2, ensure_ascii=False)

print(f"\n¡Extracción masiva completada con éxito! Archivo: '{output_path}'")