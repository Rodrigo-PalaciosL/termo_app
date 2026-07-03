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
         └── Opción C: Presión (P) y Volumen (v) ───────► [ Módulo Región P-v ]


## Módulo de Interpolación
               [ INICIO: Interpolar en Sobrecalentado ]
                                  │
                                  ▼
               ¿La Presión (P_user) existe en el JSON?
                 ├── SÍ ──► [ Caso A: Interpolación Lineal Simple ]
                 └── NO ──► [ Caso B: Interpolación Doble ]

### Caso B: Interpolación Doble
              [ Paso 1: Localizar los dos bloques de presión ]
                       P1 (X_1 kPa) < P_user < P2 (X_2 kPa)
                                      │
                                      ▼
              [ Paso 2: Interpolar por Temperatura en Bloque 1 ]
                   Hallar v, u, h a T = X°C dentro de P1 
                                      │
                                      ▼
              [ Paso 3: Interpolar por Temperatura en Bloque 2 ]
                   Hallar v, u, h a T = X°C dentro de P2
                                      │
                                      ▼
              [ Paso 4: Interpolación Final por Presión ]
                Interpolar linealmente entre los resultados de 
                        P1 y P2 para fijar el estado
                                      │
                                      ▼
                        [ ENVIAR DATOS A PANTALLA ]