import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';


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
  String horaActualizacion = "";
  Future<void> enviarWhatsApp() async {
  String hora = DateFormat('hh:mm a').format(DateTime.now());
  String monedaEnvia = _tipoOperacion == "COP a Bs" ? "COP" : "Bs";
  String monedaRecibe = _tipoOperacion == "COP a Bs" ? "Bs" : "COP";

  String envia = _formatter.format(
      int.parse(_enviaController.text.replaceAll('.', '')));

  String recibe = _formatter.format(
      int.parse(_recibeController.text.replaceAll('.', '')));

  String tasaUsada = _tipoOperacion == "COP a Bs"
      ? tasaCopABs.toString()
      : tasaBsACop.toString();

  String mensaje = """
Hola, quiero realizar este cambio:

Envio: $envia $monedaEnvia
Recibo: $recibe $monedaRecibe
Tasa ${monedaEnvia}→${monedaRecibe}: $tasaUsada
Hora: $hora
""";

  final url = Uri.parse(
    "https://wa.me/584126145680?text=${Uri.encodeComponent(mensaje)}"
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  }
}

  final TextEditingController _enviaController = TextEditingController();
  final TextEditingController _recibeController = TextEditingController();

  double tasaCopABs = 6.6;
  double tasaBsACop = 5.5;

  DateTime ultimaActualizacion = DateTime.now();
  int segundosDesdeActualizacion = 0;

  String _tipoOperacion = "COP a Bs";

  final NumberFormat _formatter = NumberFormat("#,###", "es_ES");

  bool _actualizando = false;

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
            horaActualizacion = DateFormat('hh:mm a').format(DateTime.now());
      });
    });
  }

  Future<void> cargarTasas() async {
    try {
      final url = Uri.parse(
          "https://docs.google.com/spreadsheets/d/1WksYIbs2K9x9JPvuT1qypJnhZr3Pgo1B2BfjC4GvgEc/gviz/tq?tqx=out:json");

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

 void calcularDesdeEnvia(String value) {

  if (_actualizando) return;

  _actualizando = true;

  String clean = value.replaceAll('.', '');
  double monto = double.tryParse(clean) ?? 0;

  double resultado;

  if (_tipoOperacion == "COP a Bs") {
    resultado = monto / tasaCopABs;
  } else {
    resultado = monto * tasaBsACop;
  }

  String formatted = _formatter.format(resultado.round());

  _recibeController.value = TextEditingValue(
    text: formatted,
    selection: TextSelection.collapsed(offset: formatted.length),
  );

  _actualizando = false;
}

  void calcularDesdeRecibe(String value) {

  if (_actualizando) return;

  _actualizando = true;

  String clean = value.replaceAll('.', '');
  double monto = double.tryParse(clean) ?? 0;

  double resultado;

  if (_tipoOperacion == "COP a Bs") {
    resultado = monto * tasaCopABs;
  } else {
    resultado = monto / tasaBsACop;
  }

  String formatted = _formatter.format(resultado.round());

  _enviaController.value = TextEditingValue(
    text: formatted,
    selection: TextSelection.collapsed(offset: formatted.length),
  );

  _actualizando = false;
}

  void limpiar() {
    setState(() {
      _enviaController.clear();
      _recibeController.clear();
    });
    
    
  }

  @override
  Widget build(BuildContext context) {

    String monedaEnvia = _tipoOperacion == "COP a Bs" ? "COP" : "Bs";
    String monedaRecibe = _tipoOperacion == "COP a Bs" ? "Bs" : "COP";

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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    Text(
                      "Actualizado hace $segundosDesdeActualizacion s",
                      style: const TextStyle(color: Colors.white70),
                    ),
                     Text(
                       "Hora: $horaActualizacion",
                         style: const TextStyle(color: Colors.white70),
                     ),  

                    const SizedBox(height: 15),

                    Text("COP ➜ Bs: $tasaCopABs"),
                    Text("Bs ➜ COP: $tasaBsACop"),

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
                              limpiar();
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
                              limpiar();
                            });
                          },
                          child: const Text("Bs a COP"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    TextField(
  controller: _enviaController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: "Envía ($monedaEnvia)",
  ),
  onChanged: (value) {

    if (value.isEmpty) {
      calcularDesdeEnvia(value);
      return;
    }

    String clean = value.replaceAll('.', '');

    if (clean.isNotEmpty) {

      String formatted = _formatter.format(int.parse(clean));

      if (formatted != value) {

        _enviaController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    calcularDesdeEnvia(_enviaController.text);
  },
),

                    const SizedBox(height: 15),

                    TextField(
  controller: _recibeController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: "Recibe ($monedaRecibe)",
  ),
  onChanged: (value) {

    if (value.isEmpty) {
      calcularDesdeRecibe(value);
      return;
    }

    String clean = value.replaceAll('.', '');

    if (clean.isNotEmpty) {

      String formatted = _formatter.format(int.parse(clean));

      if (formatted != value) {

        _recibeController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    calcularDesdeRecibe(_recibeController.text);
  },
),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: limpiar,
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Limpiar"),
                     ),
                     
                      const SizedBox(height: 10),

ElevatedButton.icon(
  onPressed: enviarWhatsApp,
  icon: const Icon(Icons.chat),
  label: const Text("Enviar por WhatsApp"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
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