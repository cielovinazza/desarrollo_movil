import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _keyClientes     = 'pending_clientes';
  static const _keyCotizaciones = 'pending_cotizaciones';
  static const _keyFormCliente  = 'draft_cliente';
  static const _keyFormCotizacion = 'draft_cotizacion';

  // Datos pendientes(Para guardar datos localmente cuando no hay internet o algo fallo)
  // 1. Clientes que quedaron pendientes

  Future<void> guardarClientePendiente(Map<String, dynamic> cliente) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = await obtenerClientesPendientes();
    lista.add(cliente);
    await prefs.setString(_keyClientes, jsonEncode(lista));
  }

  Future<List<Map<String, dynamic>>> obtenerClientesPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyClientes);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> limpiarClientesPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyClientes);
  }

  // 2. Cotizaciones que quedaron pendientes

  Future<void> guardarCotizacionPendiente(Map<String, dynamic> cotizacion) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = await obtenerCotizacionesPendientes();
    lista.add(cotizacion);
    await prefs.setString(_keyCotizaciones, jsonEncode(lista));
  }

  Future<List<Map<String, dynamic>>> obtenerCotizacionesPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCotizaciones);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> limpiarCotizacionesPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCotizaciones);
  }

  //Borradores de formularios temporales 
  //(Por si se cierra la app de forma inesperada antes de terminar)

  Future<void> guardarBorradorCliente(Map<String, dynamic> datos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFormCliente, jsonEncode(datos));
  }

  Future<Map<String, dynamic>?> obtenerBorradorCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFormCliente);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> limpiarBorradorCliente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFormCliente);
  }

  Future<void> guardarBorradorCotizacion(Map<String, dynamic> datos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFormCotizacion, jsonEncode(datos));
  }

  Future<Map<String, dynamic>?> obtenerBorradorCotizacion() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFormCotizacion);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> limpiarBorradorCotizacion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFormCotizacion);
  }
}