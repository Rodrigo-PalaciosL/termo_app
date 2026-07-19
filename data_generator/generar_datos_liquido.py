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
            "CoolProp no está instalado. Instálelo con 'pip install CoolProp'."
        ) from e
import CoolProp.CoolProp as CP

fluido = "Ammonia"
# Establecer referencia igual a EES (IIR)
CP.set_reference_state(fluido, 'IIR')

script_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.abspath(os.path.join(script_dir, '..', 'assets'))
if not os.path.exists(assets_dir):
    os.makedirs(assets_dir)

output_path = os.path.join(assets_dir, 'amoniaco_liquido.json')

# Límites físicos
T_crit_c = 132.25
T_triple_c = -77.7

# --- CONFIGURACIÓN DE EXTRACCIÓN ---
# Presiones para líquido comprimido (Enfoque en presiones medias y altas)
presiones_kpa = np.array([
    500.0, 1000.0, 2000.0, 5000.0, 10000.0,
    15000.0, 20000.0, 30000.0, 40000.0, 50000.0,
    60000.0, 70000.0, 80000.0, 90000.0, 100000.0,
    500000.0, 100000.0, 1500000.0, 2000000.0, 3000000.0
], dtype=np.float64)

# Rango de temperaturas en °C
T_min = -70.0
T_max = 200.0
paso_T = 5.0

temperaturas_fijas_c = np.arange(T_min, T_max + paso_T, paso_T)
# =====================================================================

bloques_liquido = []

print(f"Iniciando extracción de Líquido Comprimido para {fluido}...")

for p_kpa in presiones_kpa:
    p_pa = float(p_kpa * 1000.0)

    try:
        # Intentar obtener T_sat. Si falla (presión supercrítica), usar T_crit como límite.
        try:
            t_sat_k = float(CP.PropsSI("T", "P", p_pa, "Q", 0, fluido))
            t_sat_c = float(np.round(t_sat_k - 273.15, 2))
            es_supercritica = False
        except:
            t_sat_c = T_crit_c
            es_supercritica = True

        bloque_actual = {
            "P": float(p_kpa),
            "T_sat": t_sat_c if not es_supercritica else "N/A",
            "propiedades_por_T": []
        }

        # --- FILA 1: Líquido Saturado (solo si es subcrítico) ---
        if not es_supercritica:
            vf_sat = 1.0 / CP.PropsSI("D", "P", p_pa, "Q", 0, fluido)
            uf_sat = CP.PropsSI("U", "P", p_pa, "Q", 0, fluido) / 1000.0
            hf_sat = CP.PropsSI("H", "P", p_pa, "Q", 0, fluido) / 1000.0
            sf_sat = CP.PropsSI("S", "P", p_pa, "Q", 0, fluido) / 1000.0

            bloque_actual["propiedades_por_T"].append({
                "T": t_sat_c,
                "v": float(np.round(vf_sat, 8)),
                "u": float(np.round(uf_sat, 4)),
                "h": float(np.round(hf_sat, 4)),
                "s": float(np.round(sf_sat, 6))
            })

        # --- FILAS SIGUIENTES: Temperaturas de líquido comprimido (T < T_sat) ---
        # Filtramos temperaturas que estén por debajo de la saturación y por encima del punto triple
        temperaturas_validas = temperaturas_fijas_c[
            (temperaturas_fijas_c < t_sat_c - 0.01) & (temperaturas_fijas_c > T_triple_c)
        ]

        # Para líquido comprimido, solemos ordenar de mayor a menor temperatura o viceversa.
        # Aquí lo mantenemos ascendente.
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

        # Ordenar por temperatura para facilitar la interpolación posterior
        bloque_actual["propiedades_por_T"].sort(key=lambda x: x["T"])

        if len(bloque_actual["propiedades_por_T"]) > 0:
            bloques_liquido.append(bloque_actual)
            print(f" -> Bloque P = {p_kpa} kPa procesado. Filas: {len(bloque_actual['propiedades_por_T'])}")

    except Exception as e:
        print(f"Error en {p_kpa} kPa: {e}")

# 3. Escritura del JSON
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(bloques_liquido, f, indent=2, ensure_ascii=False)

print(f"\n¡Extracción de líquido completada! Archivo: '{output_path}'")
