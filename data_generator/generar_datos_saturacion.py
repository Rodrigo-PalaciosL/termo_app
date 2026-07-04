import os
import json
import numpy as np
import CoolProp.CoolProp as CP

# 1. Configuración de rutas automatizadas para el repositorio
script_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.abspath(os.path.join(script_dir, '..', 'assets'))

if not os.path.exists(assets_dir):
    os.makedirs(assets_dir)

output_path = os.path.join(assets_dir, 'agua_saturacion.json')

# 2. Definición de la sustancia
fluid = 'Water'

# Obtenemos las constantes críticas usando variables de estado estables (esto no falla)
# Evaluamos la temperatura crítica del fluido pidiéndole a CoolProp su valor directo
T_crit_k = CP.PropsSI('T_critical', 'P', 0, 'T', 0, fluid) 
P_crit_pa = CP.PropsSI('Pcrit', 'P', 0, 'T', 0, fluid)
rho_crit_mass = CP.PropsSI('rhocrit', 'P', 0, 'T', 0, fluid)

T_crit_c = T_crit_k - 273.15
P_crit_kpa = P_crit_pa / 1000.0
v_crit_m3kg = 1.0 / rho_crit_mass

# Rango de temperaturas en Celsius para la tabla (de 0°C a 360°C de 5 en 5)
# Filtramos para que no intente calcular por encima de la temperatura crítica
temperaturas_celsius = np.arange(0, 365, 5)

tabla_saturacion = []

print(f"Iniciando extracción masiva de propiedades para: {fluid}...")

for T_c in temperaturas_celsius:
    # Evitamos calcular exactamente en o por encima del punto crítico en el bucle para prevenir indeterminaciones
    if T_c >= T_crit_c:
        continue
        
    T_k = T_c + 273.15
    
    try:
        # --- PRESIÓN DE SATURACIÓN ---
        # Devuelve en Pa, convertimos a kPa
        P_sat = CP.PropsSI('P', 'T', T_k, 'Q', 0, fluid) / 1000.0
        
        # --- LÍQUIDO SATURADO (Calidad Q = 0) ---
        vf = 1.0 / CP.PropsSI('D', 'T', T_k, 'Q', 0, fluid)         # Volumen específico (m³/kg)
        uf = CP.PropsSI('U', 'T', T_k, 'Q', 0, fluid) / 1000.0       # Energía interna (kJ/kg)
        hf = CP.PropsSI('H', 'T', T_k, 'Q', 0, fluid) / 1000.0       # Entalpía (kJ/kg)
        sf = CP.PropsSI('S', 'T', T_k, 'Q', 0, fluid) / 1000.0       # Entropía (kJ/kg·K)
        
        # --- VAPOR SATURADO (Calidad Q = 1) ---
        vg = 1.0 / CP.PropsSI('D', 'T', T_k, 'Q', 1, fluid)         # Volumen específico (m³/kg)
        ug = CP.PropsSI('U', 'T', T_k, 'Q', 1, fluid) / 1000.0       # Energía interna (kJ/kg)
        hg = CP.PropsSI('H', 'T', T_k, 'Q', 1, fluid) / 1000.0       # Entalpía (kJ/kg)
        sg = CP.PropsSI('S', 'T', T_k, 'Q', 1, fluid) / 1000.0       # Entropía (kJ/kg·K)
        
        # Guardamos la fila con la estructura completa requerida
        tabla_saturacion.append({
            "T": float(round(T_c, 4)),
            "Psat": float(round(P_sat, 4)),
            "vf": float(round(vf, 8)),
            "vg": float(round(vg, 8)),
            "uf": float(round(uf, 4)),
            "ug": float(round(ug, 4)),
            "hf": float(round(hf, 4)),
            "hg": float(round(hg, 4)),
            "sf": float(round(sf, 6)),
            "sg": float(round(sg, 6))
        })
    except Exception as e:
        print(f"Punto omitido en T = {T_c} °C debido a límites físicos: {e}")

# 3. Estructura del JSON compatible con la App (Flutter)
estructura_json = {
    "sustancia": "Agua",
    "puntos_criticos": {
        "Tcrit": float(round(T_crit_c, 4)),
        "Pcrit": float(round(P_crit_kpa, 4)),
        "vcrit": float(round(v_crit_m3kg, 8))
    },
    "nota_calidad": "La calidad (x) es una variable independiente de entrada en la app. Q=0 para propiedades con 'f' y Q=1 para propiedades con 'g'.",
    "tabla_saturacion": tabla_saturacion
}

# 4. Escritura en el archivo final
with open(output_path, 'w', encoding='utf-8') as file:
    json.dump(estructura_json, file, indent=4, ensure_ascii=False)

print(f"\n¡Éxito absoluto!")
print(f"Archivo exportado directamente a: {output_path}")
print(f"Propiedades incluidas: T, Psat, vf, vg, uf, ug, hf, hg, sf, sg")
