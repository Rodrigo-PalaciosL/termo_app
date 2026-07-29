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
# Establecer referencia igual a EES (IIR es el estándar para Amoníaco en EES)
CP.set_reference_state(fluido, 'IIR')

script_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.abspath(os.path.join(script_dir, '..', 'assets'))
if not os.path.exists(assets_dir):
    os.makedirs(assets_dir)

output_path = os.path.join(assets_dir, 'amoniaco_sobrecalentado.json')

# Límites físicos de referencia para el Amoníaco
T_crit_c = 132.25         # Punto crítico (°C)
P_crit_pa = 11333000.0    # Presión crítica del Amoníaco (~11.33 MPa)

# --- AJUSTE DE PARÁMETROS DE EXTRACCIÓN ---
# Definimos presiones de interés en kPa
presiones_kpa = np.array([
    7.0, 8.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0,
    50.0, 100.0, 200.0, 400.0, 600.0, 800.0, 900.0,
    1000.0, 1500.0, 2000.0, 3000.0, 4000.0, 5000.0, 6000.0,
    7000.0, 8000.0, 9000.0, 10000.0, 10500.0, 11000,
    11300, 15000.0, 20000.0, 30000.0, 40000.0, 50000.0,
    60000.0, 70000.0, 80000.0, 90000.0, 100000.0,
    500000.0, 1000000.0, 1500000.0, 2000000.0, 2100000.0,
    2200000.0, 2300000.0, 2400000.0, 2500000.0,
    3000000.0, 4000000.0, 5000000.0, 6000000.0, 7000000.0,
    8000000.0, 9000000.0, 10000000.0
], dtype=np.float64)

# Rango maestro de temperaturas fijas en °C para evaluar la cuadrícula (Grid)
T_min = -75.0
T_max = 420.0
paso_T = 5.0

temperaturas_fijas_c = np.arange(T_min, T_max + paso_T, paso_T)
# =====================================================================

bloques_sobrecalentado = []

print(f"Iniciando la extracción masiva para {fluido}...")

for p_kpa in presiones_kpa:
    p_pa = float(p_kpa * 1000.0)

    try:
        # Definir los límites lógicos de la campana
        try:
            t_sat_k = float(CP.PropsSI("T", "P", p_pa, "Q", 1, fluido))
            t_sat_c = float(np.round(t_sat_k - 273.15, 2))
            is_supercritical = False
            low_pressure = True if p_kpa < 40 else False
        except:
            t_sat_c = -70  # No hay Tsat definido para presiones supercríticas
            low_pressure = True if p_kpa < 40 else False
            is_supercritical = True
            
        bloque_actual = {
            "P": float(p_kpa),
            "T_sat": t_sat_c if not is_supercritical else "N/A",
            "propiedades_por_T": []
        }

        # --- FILA 1: Vapor Saturado (solo si es subcrítico) ---
        if not is_supercritical:
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

        # --- FILAS SIGUIENTES: Temperaturas del rango ---
        if is_supercritical:
            temperaturas_validas = temperaturas_fijas_c[
                temperaturas_fijas_c > T_crit_c
            ]
        else:
            temperaturas_validas = temperaturas_fijas_c[
                (temperaturas_fijas_c > t_sat_c + 0.01)
            ]
        if low_pressure:
            temperaturas_validas = temperaturas_fijas_c[
                temperaturas_fijas_c > -75
            ]
        for t_c in temperaturas_validas:
            t_k = float(t_c + 273.15)

            try:
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
