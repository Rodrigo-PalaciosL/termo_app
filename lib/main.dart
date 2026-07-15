import 'package:flutter/material.dart';

void main() {
  runApp(const TermoApp());
}

class TermoApp extends StatelessWidget {
  const TermoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Termo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TermoApp')),
      body: const Center(
        child: Text(
          'Motor térmico listo para usar',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
