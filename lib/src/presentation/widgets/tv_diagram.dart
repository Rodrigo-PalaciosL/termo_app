import 'dart:math';
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

  // Función para calcular logaritmo en base 10
  double _log10(double x) => log(x) / ln10;

  @override
  Widget build(BuildContext context) {
    // 1. Transformación Logarítmica para el domo
    final List<FlSpot> liquidSpots = tablaSaturacion
        .map((p) => FlSpot(_log10(p.vf), p.t))
        .toList();
    
    final List<FlSpot> vaporSpots = tablaSaturacion.reversed
        .map((p) => FlSpot(_log10(p.vg), p.t))
        .toList();

    // Unión de ambas curvas para el domo completo
    final List<FlSpot> domeSpots = [...liquidSpots, ...vaporSpots];

    // 2. Transformación para el punto actual
    // Evitamos log de 0 o negativo por seguridad
    final double safeV = currentV > 0 ? currentV : 0.001;
    final double currentLogV = _log10(safeV);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Diagrama T-v (Escala Logarítmica)',
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
                        // Revertimos el log para mostrar el valor real en el tooltip
                        final double realV = pow(10, barSpot.x).toDouble();
                        return LineTooltipItem(
                          'T: ${barSpot.y.toStringAsFixed(2)} °C\nv: ${realV.toStringAsFixed(5)} m³/kg',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 40,
                  verticalInterval: 1, // Una línea por cada orden de magnitud
                  getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
                  getDrawingVerticalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('v (m³/kg)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case -3: return const Text('0.001', style: TextStyle(color: Colors.white54, fontSize: 10));
                          case -2: return const Text('0.01', style: TextStyle(color: Colors.white54, fontSize: 10));
                          case -1: return const Text('0.1', style: TextStyle(color: Colors.white54, fontSize: 10));
                          case 0: return const Text('1', style: TextStyle(color: Colors.white54, fontSize: 10));
                          case 1: return const Text('10', style: TextStyle(color: Colors.white54, fontSize: 10));
                          default: return const SizedBox();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('T (°C)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 40,
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
                // Rangos optimizados para log10(v) del amoníaco
                minX: -3.5,
                maxX: 1.5,
                minY: -80,
                maxY: 160,
                lineBarsData: [
                  // 1. El Domo de Saturación (Campana Simétrica)
                  LineChartBarData(
                    spots: domeSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
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
                    spots: [FlSpot(currentLogV, currentT)],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 7,
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
