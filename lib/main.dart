import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const FussionExpressApp());
}

class FussionExpressApp extends StatelessWidget {
  const FussionExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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

  double tasaCopABs = 6.6;
  double tasaBsACop = 5.5;

  DateTime ultimaActualizacion = DateTime.now();
  int segundosDesdeActualizacion = 0;

  String _resultado = "";
  String _tipoOperacion = "COP a Bs";

  final NumberFormat _formatter = NumberFormat("#,###", "es_ES");

  @override
  void initState() {
    super.initState();

    cargarTasas();

    Timer.periodic(const Duration(seconds: 30), (timer) {
      cargarTasas();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        segundosDesdeActualizacion =
            DateTime.now().difference(ultimaActualizacion).inSeconds;
      });
    });
  }

  Future<void> cargarTasas() async {

    try {

      final url = Uri.parse(
        "https://docs.google.com/spreadsheets/d/1WksYIbs2K9x9JPvuT1qypJnhZr3Pgo1B2BfjC4GvgEc/gviz/tq?tqx=out:json"
      );

      final response = await http.get(url);

      String data = response.body;

      data = data.substring(47);
      data = data.substring(0, data.length - 2);

      final jsonData = json.decode(data);

      final rows = jsonData["table"]["rows"];

      setState(() {
        tasaCopABs = rows[0]["c"][0]["v"].toDouble();
        tasaBsACop = rows[0]["c"][1]["v"].toDouble();

        ultimaActualizacion = DateTime.now();
        segundosDesdeActualizacion = 0;
      });

    } catch (e) {
      print("Error cargando tasas: $e");
    }
  }

  void _limpiar() {
    setState(() {
      _montoController.clear();
      _resultado = "";
    });
  }

  void _calcular() {
    setState(() {

      String montoRaw = _montoController.text.replaceAll('.', '');
      double monto = double.tryParse(montoRaw) ?? 0;

      double total;

      if (_tipoOperacion == "COP a Bs") {
        total = monto / tasaCopABs;
      } else {
        total = monto * tasaBsACop;
      }

      _resultado =
          "${_formatter.format(total.round())} ${_tipoOperacion == "COP a Bs" ? 'Bs' : 'COP'}";

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fusión Express"),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.grey[850],
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Text(
                      "🟢 Tasa en vivo",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    Text(
                      "Actualizado hace $segundosDesdeActualizacion s",
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "COP ➜ Bs: $tasaCopABs",
                      style: const TextStyle(fontSize: 16),
                    ),

                    Text(
                      "Bs ➜ COP: $tasaBsACop",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tipoOperacion == "COP a Bs"
                                ? Colors.indigo
                                : Colors.grey[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _tipoOperacion = "COP a Bs";
                            });
                          },
                          child: const Text("COP a Bs"),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tipoOperacion == "Bs a COP"
                                ? Colors.indigo
                                : Colors.grey[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _tipoOperacion = "Bs a COP";
                            });
                          },
                          child: const Text("Bs a COP"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _montoController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (value) {

                        if (value.isEmpty) return;

                        String clean = value.replaceAll('.', '');

                        if (clean.isNotEmpty) {

                          String formatted =
                              _formatter.format(int.parse(clean));

                          if (value != formatted) {

                            _montoController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          }
                        }
                        _calcular();
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        ElevatedButton(
                          onPressed: _limpiar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Limpiar"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _resultado,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

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