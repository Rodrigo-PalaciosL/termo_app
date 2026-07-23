import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/models/saturacion_model.dart';

class PvDiagram extends StatelessWidget {
  final List<PuntoSaturacion> tablaSaturacion;
  final double currentV;
  final double currentP;

  const PvDiagram({
    super.key,
    required this.tablaSaturacion,
    required this.currentV,
    required this.currentP,
  });

  // Función para calcular logaritmo en base 10
  double _log10(double x) => log(x) / ln10;

  @override
  Widget build(BuildContext context) {
    // 1. Transformación Logarítmica para el domo (Eje X: v)
    final List<FlSpot> liquidSpots = tablaSaturacion
        .map((p) => FlSpot(_log10(p.vf), p.pSat))
        .toList();
    
    final List<FlSpot> vaporSpots = tablaSaturacion.reversed
        .map((p) => FlSpot(_log10(p.vg), p.pSat))
        .toList();

    // Unión de ambas curvas para el domo completo
    final List<FlSpot> domeSpots = [...liquidSpots, ...vaporSpots];

    // 2. Transformación para el punto actual
    final double safeV = currentV > 0 ? currentV : 0.001;
    final double currentLogV = _log10(safeV);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Diagrama P-v (v en Escala Logarítmica)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        AspectRatio(
          aspectRatio: 0.8,
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
                        final double realV = pow(10, barSpot.x).toDouble();
                        return LineTooltipItem(
                          'P: ${barSpot.y.toStringAsFixed(2)} kPa\nv: ${realV.toStringAsFixed(5)} m³/kg',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10000,
                  verticalInterval: 1,
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
                    axisNameWidget: const Text('P (kPa)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: 10000,
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
                minX: -3.5,
                maxX: 1.5,
                minY: 0,
                maxY: 55000,
                lineBarsData: [
                  LineChartBarData(
                    spots: domeSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.redAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: [FlSpot(currentLogV, currentP)],
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
