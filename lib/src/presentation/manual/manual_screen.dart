import 'package:flutter/material.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual de Usuario'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Encabezado
          Text(
            'Guía de Operación: TermoApp NH₃',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const Text(
            'Versión 1.0.0 | Fluido: Amoníaco (NH₃)',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // 1. Introducción
          _buildSectionTitle(context, '1. Introducción'),
          const Text(
            'TermoApp es una herramienta interactiva diseñada para calcular propiedades termodinámicas de estado para el Amoníaco (NH₃). Utiliza datos interpolados de alta precisión para identificar la fase (Líquido Comprimido, Mezcla o Vapor Sobrecalentado) y graficar el estado en tiempo real.',
          ),
          const SizedBox(height: 20),

          // 2. Interfaz
          _buildSectionTitle(context, '2. Interfaz Principal'),
          _buildStep(
            context,
            'Entrada de Datos',
            'Selector de combinación (P-T, T-v, etc.), campos numéricos y selectores de unidades (kPa, bar, °C, K).',
            Icons.input,
          ),
          _buildStep(
            context,
            'Panel de Resultados',
            'Muestra la fase identificada y el desglose de P, T, v, u, h, s y calidad (x) si aplica.',
            Icons.analytics_outlined,
          ),
          _buildStep(
            context,
            'Diagramas T-v / P-v',
            'Representación visual con la campana de saturación y un punto rojo interactivo que indica el estado actual.',
            Icons.show_chart,
          ),
          const SizedBox(height: 10),

          // 3. Guía de Uso
          _buildSectionTitle(context, '3. Guía de Uso Paso a Paso'),
          const Text(
            'Ejemplo: Calcular estado con P y T conocidos:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            '1. Seleccione "P y T" en el menú.\n'
            '2. Ingrese la Presión (ej: 500) y la unidad (kPa).\n'
            '3. Ingrese la Temperatura (ej: 50) y la unidad (°C).\n'
            '4. Presione "CALCULATE PROPERTIES".',
          ),
          const SizedBox(height: 10),
          const Text(
            'Cambio de unidades:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Puede cambiar la unidad en los desplegables laterales en cualquier momento; la conversión y el cálculo se ajustarán automáticamente.',
          ),
          const SizedBox(height: 20),

          // 4. Límites
          _buildSectionTitle(context, '4. Límites y Errores'),
          _buildInfoCard(
            context,
            'Límites Operacionales:',
            '• Temperatura: -75 °C a 420 °C\n'
            '• Presión: 8 kPa a 10,000,000 kPa\n'
            '• Volumen específico (v): 0.0001 a 48 m³/kg\n'
            '• Calidad (x): 0.0 a 1.0 (Hasta punto crítico ~132 °C)\n'
            '• Presión Crítica: 11,363.4 kPa',
            Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 10),
          const Text(
            'Explicación de errores comunes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            '• "v fuera de rango": El volumen ingresado es demasiado grande o pequeño para la presión/temperatura dada. Esto sucede porque el estado resultante caería fuera de los límites de nuestra base de datos termodinámica y no puede ser calculado.\n'
            '• "La calidad (x) debe estar entre 0 y 1": La calidad solo es válida en la región de mezcla (saturación).\n'
            '• "Saturación. Ingrese calidad (x) o volumen (v)": A una presión y temperatura de saturación, el sistema no puede distinguir la fase sin un tercer dato. Debe calcular en otro modo.',
          ),
          const SizedBox(height: 20),

          // 5. Configuración
          _buildSectionTitle(context, '5. Personalización'),
          const Text(
            'En el menú de ajustes (barra lateral), puede alternar entre Modo Claro/Oscuro y cambiar el color de énfasis de la aplicación.',
          ),

          const Divider(height: 40),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey),
            title: Text(
              'Nota técnica',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            subtitle: Text(
              'Modelos basados en datos experimentales de saturación y vapor sobrecalentado.\n'
              'Base de datos generada con CoolProp',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
