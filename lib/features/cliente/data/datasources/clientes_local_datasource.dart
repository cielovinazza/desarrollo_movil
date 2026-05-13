import 'dart:convert';
import 'package:flutter/services.dart';

class ClientesLocalDataSource {

  List<Map<String, dynamic>> _clientes = [];
  bool _inicializado = false;

  Future<void> _init() async {
    if (_inicializado) return;

    final jsonString =
        await rootBundle.loadString('assets/data/clientes.json');

    final List data = jsonDecode(jsonString);

    _clientes = data.cast<Map<String, dynamic>>();
    _inicializado = true;
  }

  Future<List<Map<String, dynamic>>> getClientes() async {
    await _init();
    return _clientes;
  }

  Future<void> agregarCliente(Map<String, dynamic> cliente) async {
    await _init();
    _clientes.add(cliente);
  }
}