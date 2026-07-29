===========================================================================================
# FUNCIONAMIENTO GENERAL DE LA APLICACIÓN
===========================================================================================

##                                [ INICIO DE LA APP ]
                                            │
                                            ▼
                       [ CARGAR ARCHIVO DE CONFIGURACIÓN (JSON) ]
                       - Carga datos del gas de referencia (Amoniaco)
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
                    /         /          │          \          \
                   /         /           │           \          \
             [ P & T ]   [ T & v ]   [ P & v ]   [ T & x ]   [ P & x ]
                │           │           │           │           │
                ▼           ▼           ▼           ▼           ▼
             (Mod A)     (Mod B)     (Mod C)     (Mod D)     (Mod E)



## Módulo A: Lógica para Entrada Presión & Temperatura

                                 (Viene de Opción 1)
                                         │
                                         ▼
                 [ ¿Presión es Supercrítica? (P > P_crit) ]
                 ├── SÍ ──► [ Resolver como Líquido o Vapor ]
                 └── NO ──► [ Hallar T_sat a P_user ]
                                         │
                                         ▼
                               ¿T_user vs T_sat?
                 ┌───────────────────────┼───────────────────────┐
                 ▼                       ▼                       ▼
            (T_user < T_sat)        (T_user = T_sat)        (T_user > T_sat)
                 │                       │                       │
                 ▼                       ▼                       ▼
      [ LÍQUIDO COMPRIMIDO ]      ⚠️ [ INDETERMINADO ]      [ VAPOR SOBRECALENTADO ]
     - Intentar interpolar en     - Detener proceso       - Ir a tabla_sobrecalentado
       tabla_liquido              - Alerta: Requiere      - Ejecutar INTERPOLACIÓN DOBLE
     - Fallback: Usar vf a T        v o calidad (x)         para calcular: v, u, h, s
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
               - Si no es exacta, interpola para hallar v_f y v_g
                                         │
                                         ▼
                              ¿v_user vs (v_f y v_g)?
                 ┌───────────────────────┼───────────────────────┐
                 ▼                       ▼                       ▼
            (v_user < v_f)         (v_f <= v_user <= v_g)        (v_user > v_g)
                 │                       │                       │
                 ▼                       ▼                       ▼
      [ LÍQUIDO COMPRIMIDO ]          [ MEZCLA HÚMEDA ]     [ VAPOR SOBRECALENTADO ]
     - Intentar interpolar en     - Presión final = P_sat  - Ir a tabla_sobrecalentado
       tabla_liquido              - Calcular Calidad:      - Ejecutar INTERPOLACIÓN DOBLE
     - Fallback: Usar vf a T        x = (v-vf)/(vg-vf)       (Usar _interpolarGas para P)
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
               - Si no es exacta, interpola para hallar T_sat, v_f y v_g
                                         │
                                         ▼
                              ¿v_user vs (v_f y v_g)?
                 ┌───────────────────────┼───────────────────────┐
                 ▼                       ▼                       ▼
            (v_user < v_f)         (v_f <= v_user <= v_g)        (v_user > v_g)
                 │                       │                       │
                 ▼                       ▼                       ▼
      [ LÍQUIDO COMPRIMIDO ]          [ MEZCLA HÚMEDA ]     [ VAPOR SOBRECALENTADO ]
     - Intentar interpolar en     - Temp final = T_sat     - Ir a tabla_sobrecalentado
       tabla_liquido              - Calcular Calidad:      - Ejecutar INTERPOLACIÓN DOBLE
     - Fallback: Usar vf a P        x = (v-vf)/(vg-vf)       (Usar _interpolarGas para v)
                 │                       │                       │
                 └───────────────────────┼───────────────────────┘
                                         │
                                         ▼
                              (Ir a Módulo de Salida)

## Módulo D y E: Lógica para Saturación (x)

                            (Viene de Opción 4 o 5)
                                         │
                                         ▼
               [ Buscar T_user o P_user en tabla_saturacion ]
                                         │
                                         ▼
                              [ MEZCLA HÚMEDA ]
               - Calcular v, u, h, s usando la calidad x:
                 Prop = Prop_f + x * (Prop_g - Prop_f)
                                         │
                                         ▼
                              (Ir a Módulo de Salida)

## Módulo de Salida: Renderizado Gráfico y Resultados

                            (Viene de cualquiera de los módulos)
                                             │
                                             ▼
                        [ ENVIAR RESULTADOS NUMÉRICOS A LA INTERFAZ ]
                        - Muestra en pantalla: T, P, v, u, h, s, x y Fase
                                             │
                                             ▼
                        [ PROCESAR COORDENADAS PARA LOS CANVAS ]
                        - Diagrama T-v: Eje X=v, Eje Y=T
                        - Diagrama P-v: Eje X=v, Eje Y=P
                                             │
                                             ▼
                        [ DIBUJAR COMPONENTES VISUALES EN PANTALLA ]
                        1. Dibuja la curva de la Campana de Saturación
                        2. Dibuja líneas de presión/temperatura constante (Isotermas/Isobaras)
                        3. Posiciona el Marcador (Punto de Estado)
                                             │
                                             ▼
                                     [ FIN DEL PROCESO ]
===========================================================================================
