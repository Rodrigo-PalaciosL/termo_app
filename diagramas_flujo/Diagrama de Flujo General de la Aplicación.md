===========================================================================================
# FUNCIONAMIENTO GENERAL DE LA APLICACIÓN
===========================================================================================

##                                [ INICIO DE LA APP ]
                                            │
                                            ▼
                       [ CARGAR ARCHIVO DE CONFIGURACIÓN (JSON) ]
                       - Carga datos del gas de referencia (Agua)
                       - Guarda en memoria: P_critica, T_critica, v_critico
                       - Carga matrices: tabla_saturacion y tabla_sobrecalentado
                                            │
                                            ▼
                       [ PANTALLA PRINCIPAL: CAPTURA DE DATOS ]
                       - El usuario selecciona qué 2 propiedades va a ingresar.
                       - El usuario ingresa los valores numéricos correspondientes.
                                            │
                                            ▼
                    =================================================
                          ¿Qué combinación de entradas se eligió?
                    =================================================
                         /                  │                  \
                        /                   │                   \
    [ Opción 1: Presión & Temp ]  [ Opción 2: Temp & Vol ]  [ Opción 3: Presión & Vol ]
                        │                   │                   │
                        ▼                   ▼                   ▼
                (Ir a Módulo A)     (Ir a Módulo B)     (Ir a Módulo C)



## Módulo A: Lógica para Entrada Presión & Temperatura

                                 (Viene de Opción 1)
                                         │
                                         ▼
              [ Buscar P_user en la matriz JSON de tabla_saturacion ]
              - Si no es exacta, interpola linealmente para hallar T_sat
                                         │
                                         ▼
                               ¿T_user vs T_sat?
                 ┌───────────────────────┼───────────────────────┐
                 ▼                       ▼                       ▼
            (T_user < T_sat)        (T_user = T_sat)        (T_user > T_sat)
                 │                       │                       │
                 ▼                       ▼                       ▼
      [ LÍQUIDO COMPRIMIDO ]      ⚠️ [ INDETERMINADO ]      [ VAPOR SOBRECALENTADO ]
     - Alerta: Fuera de rango     - Detener proceso       - Ir a tabla_sobrecalentado
       actual de tablas           - Alerta: Requiere      - Ejecutar INTERPOLACIÓN DOBLE
                                    v o calidad (x)         para calcular: v, u, h
                 │                       │                       │
                 └───────────────────────┼───────────────────────┘
                                         │
                                         ▼
                              (Ir a Módulo de Salida)



## Módulo B: Lógica para Entrada Temperatura & Volumen específico

                                (Viene de Opción 2)
                                         │
                                         ▼
               [ Buscar T_user en matriz JSON de tabla_saturacion ]
               - Si no es exacta, interpola linealmente para hallar v_f y v_g
                                         │
                                         ▼
                              ¿v_user vs (v_f y v_g)?
                 ┌───────────────────────┼───────────────────────┐
                 ▼                       ▼                       ▼
            (v_user < v_f)         (v_f <= v_user <= v_g)        (v_user > v_g)
                 │                       │                       │
                 ▼                       ▼                       ▼
      [ LÍQUIDO COMPRIMIDO ]          [ MEZCLA HÚMEDA ]     [ VAPOR SOBRECALENTADO ]
     - Alerta: Fuera de rango     - Presión final = P_sat  - Ir a tabla_sobrecalentado
       actual de tablas           - Calcular Calidad:      - Buscar bloques de Presión
                                    x = (v-vf)/(vg-vf)       que encierren v_user a T_user
                                  - Calcular h y u usando  - Ejecutar INTERPOLACIÓN DOBLE
                                    la calidad x            para calcular: P, u, h
                 │                       │                       │
                 └───────────────────────┼───────────────────────┘
                                         │
                                         ▼
                              (Ir a Módulo de Salida)



## Módulo C: Lógica para Entrada Presión & Volumen específico

                                (Viene de Opción 3)
                                         │
                                         ▼
               [ Buscar P_user en matriz JSON de tabla_saturacion ]
               - Si no es exacta, interpola linealmente para hallar T_sat, v_f y v_g
                                         │
                                         ▼
                              ¿v_user vs (v_f y v_g)?
                 ┌───────────────────────┼───────────────────────┐
                 ▼                       ▼                       ▼
            (v_user < v_f)         (v_f <= v_user <= v_g)        (v_user > v_g)
                 │                       │                       │
                 ▼                       ▼                       ▼
      [ LÍQUIDO COMPRIMIDO ]          [ MEZCLA HÚMEDA ]     [ VAPOR SOBRECALENTADO ]
     - Alerta: Fuera de rango     - Temp final = T_sat     - Ir a tabla_sobrecalentado
       actual de tablas           - Calcular Calidad:      - Localizar bloques P1 y P2
                                    x = (v-vf)/(vg-vf)       vecinos a P_user
                                  - Calcular h y u usando  - Ejecutar INTERPOLACIÓN DOBLE
                                    la calidad x            para calcular: T, u, h
                 │                       │                       │
                 └───────────────────────┼───────────────────────┘
                                         │
                                         ▼
                              (Ir a Módulo de Salida)

## Módulo de Salida: Renderizado Gráfico y Resultados

                            (Viene de cualquiera de los módulos)
                                             │
                                             ▼
                        [ ENVIAR RESULTADOS NUMÉRICOS A LA INTERFAZ ]
                        - Muestra en pantalla: T, P, v, u, h y Estado Físico
                                             │
                                             ▼
                        [ PROCESAR COORDENADAS PARA EL CANVAS (GRAFICO) ]
                        - Variable Eje X = v_final (Volumen específico)
                        - Variable Eje Y = T_final (Temperatura)
                                             │
                                             ▼
                        [ DIBUJAR COMPONENTES VISUALES EN PANTALLA ]
                        1. Dibuja la curva fija de la Campana usando (v_f, T) y (v_g, T)
                        2. Si es Mezcla, dibuja la línea horizontal de T constante
                        3. Posiciona el Marcador (Punto de Estado) en la coordenada (v, T)
                                             │
                                             ▼
                                     [ FIN DEL PROCESO ]
===========================================================================================
