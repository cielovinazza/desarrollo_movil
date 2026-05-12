import 'dart:convert';
import 'package:flutter/services.dart';

class ClientesLocalDataSource {

  Future<List<dynamic>> getClientes() async {
    final jsonString =
        await rootBundle.loadString('assets/data/clientes.json');

    final List data = jsonDecode(jsonString);
    return data;
  }
}