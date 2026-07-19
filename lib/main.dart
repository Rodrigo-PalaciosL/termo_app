import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/data/models/termo_database.dart';
import 'src/domain/engine/termo_engine.dart';
import 'src/utils/unit_converter.dart';

void main() {
  runApp(const TermoApp());
}

class TermoApp extends StatelessWidget {
  const TermoApp({super.key});

  @override //Ejecutor clave
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Termo App',
      debugShowCheckedModeBanner: false, //Oculta el banner de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  TermoEngine? _engine;
  bool _isLoading = true;
  String? _errorMessage;

  // Controladores para los campos de entrada
  final TextEditingController _val1Controller = TextEditingController();
  final TextEditingController _val2Controller = TextEditingController();

  String _selectedMode = 'T-v'; // Modos: 'T-v', 'P-T', 'P-v', 'T-x', 'P-x'
  EstadoTermodinamico? _resultado;

  // Unidades seleccionadas
  String _u1 = '°C'; // Para T o P
  String _u2 = 'm³/kg'; // Para v, T o x

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    try {
      final String satData =
          await rootBundle.loadString('assets/amoniaco_saturacion.json');
      final String sobreData =
          await rootBundle.loadString('assets/amoniaco_sobrecalentado.json');
      final String liqData =
          await rootBundle.loadString('assets/amoniaco_liquido.json');

      final Map<String, dynamic> satJson = jsonDecode(satData);
      final List<dynamic> sobreJson = jsonDecode(sobreData);
      final List<dynamic> liqJson = jsonDecode(liqData);

      final db = TermoDatabase.fromRawData(
        jsonSaturacion: satJson['tabla_saturacion'] as List<dynamic>,
        jsonSobrecalentado: sobreJson,
        jsonLiquido: liqJson,
      );

      setState(() {
        _engine = TermoEngine(db: db);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error al cargar datos: $e";
        _isLoading = false;
      });
    }
  }

  void _calcular() {
    if (_engine == null) return;

    double? v1 = double.tryParse(_val1Controller.text);
    double? v2 = double.tryParse(_val2Controller.text);

    if (v1 == null || v2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa valores numéricos')),
      );
      return;
    }

    // --- CONVERSIÓN DE ENTRADA ---
    // Convertir v1
    if (_selectedMode.startsWith('T')) {
      v1 = UnitConverter.toCelsius(v1, _u1);
    } else if (_selectedMode.startsWith('P')) {
      v1 = UnitConverter.toKpa(v1, _u1);
    }

    // Convertir v2
    if (_selectedMode.endsWith('v')) {
      v2 = UnitConverter.toM3kg(v2, _u2);
    } else if (_selectedMode.endsWith('T')) {
      v2 = UnitConverter.toCelsius(v2, _u2);
    }
    // Si es 'x', no hay conversión (se asume 0-1)

    try {
      EstadoTermodinamico res;
      if (_selectedMode == 'T-v') {
        res = _engine!.resolverEstadoPorTyV(v1, v2);
      } else if (_selectedMode == 'P-T') {
        res = _engine!.resolverEstadoPorPyT(v1, v2);
      } else if (_selectedMode == 'T-x') {
        res = _engine!.resolverEstadoPorTyX(v1, v2);
      } else if (_selectedMode == 'P-x') {
        res = _engine!.resolverEstadoPorPyX(v1, v2);
      } else {
        res = _engine!.resolverEstadoPorPv(v1, v2);
      }

      setState(() {
        _resultado = res;
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TermoApp - Motor Térmico'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selección de modo
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'T-v',
                        child: Text('Temperatura (°C) y Volumen (m³/kg)'),
                      ),
                      DropdownMenuItem(
                        value: 'P-v',
                        child: Text('Presión (kPa) y Volumen (m³/kg)'),
                      ),
                      DropdownMenuItem(
                        value: 'P-T',
                        child: Text('Presión (kPa) y Temperatura (°C)'),
                      ),
                      DropdownMenuItem(
                        value: 'T-x',
                        child: Text('Temperatura (°C) y Calidad (x)'),
                      ),
                      DropdownMenuItem(
                        value: 'P-x',
                        child: Text('Presión (kPa) y Calidad (x)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMode = value!;
                        _resultado = null;
                        // Ajustar unidades por defecto según el modo
                        if (_selectedMode.startsWith('T')) {
                          _u1 = '°C';
                        } else {
                          _u1 = 'kPa';
                        }

                        if (_selectedMode.endsWith('v')) {
                          _u2 = 'm³/kg';
                        } else if (_selectedMode.endsWith('T')) {
                          _u2 = '°C';
                        } else {
                          _u2 = 'x'; // Calidad no tiene unidad SI diferente usualmente
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Entradas
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _val1Controller,
                    decoration: InputDecoration(
                      labelText: (_selectedMode.startsWith('T')) ? 'T' : 'P',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildUnitDropdown(
                    value: _u1,
                    items: _selectedMode.startsWith('T')
                        ? ['°C', 'K']
                        : ['kPa', 'Pa', 'MPa', 'bar'],
                    onChanged: (val) => setState(() => _u1 = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _val2Controller,
                    decoration: InputDecoration(
                      labelText: (_selectedMode.endsWith('v'))
                          ? 'v'
                          : (_selectedMode.endsWith('T') ? 'T' : 'x (0 - 1)'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_selectedMode.endsWith('x'))
                  Expanded(
                    flex: 2,
                    child: _buildUnitDropdown(
                      value: _u2,
                      items: _selectedMode.endsWith('v')
                          ? ['m³/kg', 'cm³/g', 'L/kg']
                          : ['°C', 'K'],
                      onChanged: (val) => setState(() => _u2 = val!),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular Estado'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            if (_resultado != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _resultado!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados: ${res.fase}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            _buildResultRow('Presión (P):', '${res.p.toStringAsFixed(2)} kPa'),
            _buildResultRow(
              'Temperatura (T):',
              '${res.t.toStringAsFixed(2)} °C',
            ),
            _buildResultRow(
              'Volumen (v):',
              '${res.v.toStringAsFixed(5)} m³/kg',
            ),
            _buildResultRow(
              'Energía Int. (u):',
              '${res.u.toStringAsFixed(2)} kJ/kg',
            ),
            _buildResultRow(
              'Entalpía (h):',
              '${res.h.toStringAsFixed(2)} kJ/kg',
            ),
            _buildResultRow(
              'Entropía (s):',
              '${res.s.toStringAsFixed(4)} kJ/kg·K',
            ),
            if (res.x != null)
              _buildResultRow(
                'Calidad (x):',
                '${(res.x! * 100).toStringAsFixed(2)} %',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }
}
