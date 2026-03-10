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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
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

  final TextEditingController _enviaController = TextEditingController();
  final TextEditingController _recibeController = TextEditingController();

  final NumberFormat _formatter = NumberFormat("#,###", "es_ES");

  double tasaCopABs = 6.6;
  double tasaBsACop = 5.5;
  double usdVenta = 4100;
  double usdCompra = 3550;

  DateTime ultimaActualizacion = DateTime.now();
  int segundosDesdeActualizacion = 0;
  String horaActualizacion = "";

  String _tipoOperacion = "COP a Bs";

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
        usdVenta = rows[0]["c"][2]["v"].toDouble();
        usdCompra = rows[0]["c"][3]["v"].toDouble();

        ultimaActualizacion = DateTime.now();
        segundosDesdeActualizacion = 0;
      });
    } catch (e) {
      print("Error cargando tasas: $e");
    }
  }

  Future<void> enviarWhatsApp() async {

  int enviaNumero =
      int.tryParse(_enviaController.text.replaceAll('.', '')) ?? 0;

  int recibeNumero =
      int.tryParse(_recibeController.text.replaceAll('.', '')) ?? 0;

  if (enviaNumero == 0 && recibeNumero == 0) return;

  String hora = DateFormat('hh:mm a').format(DateTime.now());

  String monedaEnvia;
  String monedaRecibe;
  String tasaTexto = "";

  if (_tipoOperacion == "COP a Bs") {
    monedaEnvia = "COP";
    monedaRecibe = "Bs";
    tasaTexto = "Tasa COP→Bs: $tasaCopABs";
  }

  else if (_tipoOperacion == "Bs a COP") {
    monedaEnvia = "Bs";
    monedaRecibe = "COP";
    tasaTexto = "Tasa Bs→COP: $tasaBsACop";
  }

  else if (_tipoOperacion == "USD a COP") {
    monedaEnvia = "USD";
    monedaRecibe = "COP";
    tasaTexto = "USD Compra: ${_formatter.format(usdCompra.round())} COP";
  }

  else {
    monedaEnvia = "COP";
    monedaRecibe = "USD";
    tasaTexto = "USD Venta: ${_formatter.format(usdVenta.round())} COP";
  }

  String envia = _formatter.format(enviaNumero);
  String recibe = _formatter.format(recibeNumero);

  String mensaje = """
Hola, quiero realizar este cambio:

Envio: $envia $monedaEnvia
Recibo: $recibe $monedaRecibe
$tasaTexto
Hora: $hora
""";

  final url = Uri.parse(
      "https://wa.me/584126145680?text=${Uri.encodeComponent(mensaje)}");

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  }
}

  void calcularDesdeEnvia(String value) {

    if (_actualizando) return;
    _actualizando = true;

    String clean = value.replaceAll('.', '');
    double monto = double.tryParse(clean) ?? 0;

    double resultado = 0;

    if (_tipoOperacion == "COP a Bs") {
      resultado = monto / tasaCopABs;
    }

    else if (_tipoOperacion == "Bs a COP") {
      resultado = monto * tasaBsACop;
    }

    else if (_tipoOperacion == "USD a COP") {
      resultado = monto * usdCompra;
    }

    else if (_tipoOperacion == "COP a USD") {
      resultado = monto / usdVenta;
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

    double resultado = 0;

    if (_tipoOperacion == "COP a Bs") {
      resultado = monto * tasaCopABs;
    }

    else if (_tipoOperacion == "Bs a COP") {
      resultado = monto / tasaBsACop;
    }

    else if (_tipoOperacion == "USD a COP") {
      resultado = monto / usdCompra;
    }

    else if (_tipoOperacion == "COP a USD") {
      resultado = monto * usdVenta;
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

  Widget botonOperacion(String texto) {

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _tipoOperacion = texto;
          limpiar();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _tipoOperacion == texto
            ? Colors.blueAccent
            : const Color(0xFF2A2A2A),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(texto),
    );
  }

  @override
  Widget build(BuildContext context) {

    String monedaEnvia;
    String monedaRecibe;

    if (_tipoOperacion == "COP a Bs") {
      monedaEnvia = "COP";
      monedaRecibe = "Bs";
    } else if (_tipoOperacion == "Bs a COP") {
      monedaEnvia = "Bs";
      monedaRecibe = "COP";
    } else if (_tipoOperacion == "USD a COP") {
      monedaEnvia = "USD";
      monedaRecibe = "COP";
    } else {
      monedaEnvia = "COP";
      monedaRecibe = "USD";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fusión Express"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 500,
          child: Card(
            elevation: 20,
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "🟢 Tasa en vivo",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  Text("Actualizado hace $segundosDesdeActualizacion s"),
                  Text("Hora: $horaActualizacion"),

                  const SizedBox(height: 15),

                  Text("COP ➜ Bs: $tasaCopABs"),
                  Text("Bs ➜ COP: $tasaBsACop"),
                  Text("USD Venta: ${_formatter.format(usdVenta.round())} COP"),
                  Text("USD Compra: ${_formatter.format(usdCompra.round())} COP"),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    children: [
                      botonOperacion("COP a Bs"),
                      botonOperacion("Bs a COP"),
                      botonOperacion("USD a COP"),
                      botonOperacion("COP a USD"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _enviaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Envía ($monedaEnvia)",
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
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
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
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
    );
  }
}