import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/cliente.dart';

class ClientesLocalDataSource {
  // 1. Patrón Singleton: Asegura una única instancia en toda la app
  static final ClientesLocalDataSource _instance = ClientesLocalDataSource._internal();
  factory ClientesLocalDataSource() => _instance;
  ClientesLocalDataSource._internal();

  // 2. Estado de la data en memoria
  List<Cliente> _clientes = [];
  bool _inicializado = false;

  // 3. Inicialización: Carga el JSON solo la primera vez
  Future<void> _init() async {
    if (_inicializado) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/clientes.json');
      final List dynamicList = jsonDecode(jsonString);

      // Mapeo de JSON a Entidades Cliente
      _clientes = dynamicList.map((json) => Cliente.fromJson(json)).toList();
      _inicializado = true;
    } catch (e) {
      // Usamos un log básico para evitar alertas de producción
      // ignore: avoid_print
      print("Error al inicializar el JSON: $e");
    }
  }

  // 4. Obtener todos los clientes
  Future<List<Cliente>> getClientes() async {
    await _init();
    return _clientes;
  }

  // 5. Agregar un nuevo cliente (Simula un POST de API)
  Future<void> agregarCliente(Cliente cliente) async {
    await _init();

    // Generación de ID incremental manual para la simulación
    final nuevoId = _clientes.isEmpty ? 1 : (_clientes.last.id ?? 0) + 1;
    final clienteConId = cliente.copyWith(id: nuevoId);

    _clientes.add(clienteConId);
  }

  // 6. Editar un cliente existente (Este es el que te faltaba y daba error)
  Future<void> editarCliente(Cliente clienteActualizado) async {
    await _init();
    
    // Buscamos el índice por ID
    final index = _clientes.indexWhere((c) => c.id == clienteActualizado.id);
    
    if (index != -1) {
      // Reemplazamos el objeto en la lista por el nuevo
      _clientes[index] = clienteActualizado;
    } else {
      // ignore: avoid_print
      print("No se encontró el cliente con ID: ${clienteActualizado.id}");
    }
  }
}