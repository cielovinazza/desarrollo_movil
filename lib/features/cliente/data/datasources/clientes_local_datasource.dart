import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/cliente.dart';

class ClientesLocalDataSource {
  static final ClientesLocalDataSource _instance = ClientesLocalDataSource._internal();
  factory ClientesLocalDataSource() => _instance;
  ClientesLocalDataSource._internal();
  List<Cliente> _clientes = [];
  bool _inicializado = false;

  Future<void> _init() async {
    if (_inicializado) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/clientes.json');
      final List dynamicList = jsonDecode(jsonString);
      _clientes = dynamicList.map((json) => Cliente.fromJson(json)).toList();
      _inicializado = true;
    } catch (e) {
      print("Error al inicializar el JSON: $e");
    }
  }

  // 4. Obtener todos los clientes
  Future<List<Cliente>> getClientes() async {
    await _init();
    return _clientes;
  }

  Future<void> agregarCliente(Cliente cliente) async {
    await _init();

    final nuevoId = _clientes.isEmpty ? 1 : (_clientes.last.id ?? 0) + 1;
    final clienteConId = cliente.copyWith(id: nuevoId);

    _clientes.add(clienteConId);
  }

  Future<void> editarCliente(Cliente clienteActualizado) async {
    await _init();
    final index = _clientes.indexWhere((c) => c.id == clienteActualizado.id);
    
    if (index != -1) {
      _clientes[index] = clienteActualizado;
    } else {
      // ignore: avoid_print
      print("No se encontró el cliente con ID: ${clienteActualizado.id}");
    }
  }
}