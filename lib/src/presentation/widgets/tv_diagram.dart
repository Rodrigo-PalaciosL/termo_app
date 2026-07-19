import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/models/saturacion_model.dart';

class TvDiagram extends StatelessWidget {
  final List<PuntoSaturacion> tablaSaturacion;
  final double currentV;
  final double currentT;

  const TvDiagram({
    super.key,
    required this.tablaSaturacion,
    required this.currentV,
    required this.currentT,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Crear series de puntos para el domo
    // Línea de líquido saturado (vf, T)
    final List<FlSpot> liquidSpots = tablaSaturacion.map((p) => FlSpot(p.vf, p.t)).toList();
    
    // Línea de vapor saturado (vg, T)
    // Se ordena de mayor T a menor T para que al unir con líquido (menor T a mayor T)
    // se forme un ciclo continuo (domo)
    final List<FlSpot> vaporSpots = tablaSaturacion.reversed.map((p) => FlSpot(p.vg, p.t)).toList();

    // Unión de ambas curvas para el domo completo
    final List<FlSpot> domeSpots = [...liquidSpots, ...vaporSpots];

    // Lógica de escala inteligente para el eje X
    // Si el punto actual está muy a la derecha, expandimos el eje
    double maxX = 2.0; 
    if (currentV > maxX) {
      maxX = (currentV * 1.2).clamp(0, 50); // Límite razonable para visualización
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Diagrama Temperatura - Volumen Específico (T-v)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.blueGrey.withValues(alpha: 0.9),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        return LineTooltipItem(
                          'T: ${barSpot.y.toStringAsFixed(2)} °C\nv: ${barSpot.x.toStringAsFixed(4)} m³/kg',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
                  getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('v (m³/kg)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) return const SizedBox();
                        return Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white54, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('T (°C)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                minX: 0,
                maxX: maxX,
                minY: -80,
                maxY: 160,
                lineBarsData: [
                  // 1. El Domo de Saturación
                  LineChartBarData(
                    spots: domeSpots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                  ),
                  // 2. Punto del Estado Actual
                  LineChartBarData(
                    spots: [FlSpot(currentV, currentT)],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Colors.orangeAccent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      ],
    );
  }
}
