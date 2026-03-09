import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const FussionExpressApp());
}

class FussionExpressApp extends StatelessWidget {
  const FussionExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Activa el tema oscuro por defecto
      home: const CalculadoraScreen(),
    );
  }
}

class CalculadoraScreen extends StatefulWidget {
  const CalculadoraScreen({super.key});
  @override
  State<CalculadoraScreen> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _tasaController = TextEditingController();
  String _resultado = "";
  String _tipoOperacion = "Pesos a Bs";
  final NumberFormat _formatter = NumberFormat("#,###", "es_ES");

  void _limpiar() {
    setState(() {
      _montoController.clear();
      _tasaController.clear();
      _resultado = "";
    });
  }

  void _calcular() {
    setState(() {
      String montoRaw = _montoController.text.replaceAll('.', '');
      String tasaRaw = _tasaController.text.replaceAll(',', '.');
      double monto = double.tryParse(montoRaw) ?? 0.0;
      double tasa = double.tryParse(tasaRaw) ?? 0.0;
      if (tasa <= 0) {
        _resultado = "Error: Tasa inválida";
        return;
      }
      double total = (_tipoOperacion == "Pesos a Bs") ? (monto / tasa) : (monto * tasa);
      _resultado = "${_formatter.format(total.round())} ${_tipoOperacion == "Pesos a Bs" ? 'Bs' : 'COP'}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fusión Express"), backgroundColor: Colors.indigo),
      body: Container(
        color: Colors.grey[900], // Fondo oscuro profundo
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.grey[850], // Tarjeta gris oscuro
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tipoOperacion == "Pesos a Bs" ? Colors.indigo : Colors.grey[700],
                          ),
                          onPressed: () => setState(() => _tipoOperacion = "Pesos a Bs"),
                          child: const Text("Pesos a Bs"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tipoOperacion == "Bs a Pesos" ? Colors.indigo : Colors.grey[700],
                          ),
                          onPressed: () => setState(() => _tipoOperacion = "Bs a Pesos"),
                          child: const Text("Bs a Pesos"),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Monto', labelStyle: TextStyle(color: Colors.white70)),
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        String clean = value.replaceAll('.', '');
                        if (clean.isNotEmpty) {
                          String formatted = _formatter.format(int.parse(clean));
                          if (value != formatted) {
                            _montoController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        }
                      },
                    ),
                    TextField(
                      controller: _tasaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tasa (usa . o ,)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: _calcular, child: const Text("Calcular")),
                        ElevatedButton(
                          onPressed: _limpiar,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                          child: const Text("Limpiar"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(_resultado, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}