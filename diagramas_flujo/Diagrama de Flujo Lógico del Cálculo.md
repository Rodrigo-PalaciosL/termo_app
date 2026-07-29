===========================================================================================
# OPERACIÓN DE CÁLCULO
===========================================================================================

##     [ INICIO: Usuario presiona Calcular ]
                         │
                         ▼
    [ Leer variables de entrada y Gas seleccionado ]
                         │
                         ▼
        ¿Qué combinación de datos se ingresó?
         ├── Opción A: Presión (P) y Temperatura (T) ───► [ Módulo Región P-T ]
         ├── Opción B: Temperatura (T) y Volumen (v) ───► [ Módulo Región T-v ]
         ├── Opción C: Presión (P) y Volumen (v) ───────► [ Módulo Región P-v ]
         ├── Opción D: Temperatura (T) y Calidad (x) ───► [ Módulo Saturación T-x ]
         └── Opción E: Presión (P) y Calidad (x) ───────► [ Módulo Saturación P-x ]


## Módulo de Interpolación
               [ INICIO: Interpolar en Tablas (Liq/Sob) ]
                                  │
                                  ▼
               ¿La propiedad primaria existe en el JSON?
                 ├── SÍ ──► [ Caso A: Interpolación Lineal Simple en T o P ]
                 └── NO ──► [ Caso B: Interpolación Doble (P-T, P-v, etc.) ]

### Caso B: Interpolación Doble
              [ Paso 1: Localizar los dos bloques de presión ]
                       P1 (X_1 kPa) < P_user < P2 (X_2 kPa)
                                      │
                                      ▼
              [ Paso 2: Interpolar por propiedad secundaria en Bloque 1 ]
                   Hallar v, u, h, s a T = T_user (o v_user) dentro de P1 
                                      │
                                      ▼
              [ Paso 3: Interpolar por propiedad secundaria en Bloque 2 ]
                   Hallar v, u, h, s a T = T_user (o v_user) dentro de P2
                                      │
                                      ▼
              [ Paso 4: Interpolación Final por Presión ]
                Interpolar entre los resultados de P1 y P2.
                * Nota: Para 'v' y 'P' se usa Interpolación de Gas (P·v ≈ const)
                  en zonas de vapor.
                                      │
                                      ▼
                        [ ENVIAR DATOS A PANTALLA ]
