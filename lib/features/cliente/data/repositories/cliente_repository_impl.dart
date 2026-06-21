import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/clientes_remote_datasource.dart';
import '../mappers/cliente_mapper.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  final ClientesRemoteDataSource remoteDataSource;
  final LocalStorage _localStorage = LocalStorage();

  ClienteRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> registrarCliente(Cliente cliente) async {
    final dto = ClienteMapper.toDto(cliente);
    await remoteDataSource.agregarCliente(dto);
    await remoteDataSource.getClientes(forzarServidor: true);
  }

  @override
  Future<List<Cliente>> listarClientes() async {
    List<Cliente> clientesRemotos = [];
    
    try {
      final dtos = await remoteDataSource.getClientes();
      clientesRemotos = dtos.map((dto) => ClienteMapper.toEntity(dto)).toList();
    } catch (_) {
    }

    final pendientesMap = await _localStorage.obtenerClientesPendientes();
    final clientesPendientes = pendientesMap.map((map) {
      return Cliente(
        id: map['id']?.toString() ?? map['rut']?.toString() ?? '',
        nombre: map['nombre']?.toString() ?? '',
        rut: map['rut']?.toString() ?? '',
        correo: map['correo']?.toString() ?? '',
        telefono: map['telefono']?.toString() ?? '',
        direccion: map['direccion']?.toString(),
      );
    }).toList();

    final editadosMap = await _localStorage.obtenerClientesEditadosPendientes();
    final clientesEditados = editadosMap.map((map) {
      return Cliente(
        id: map['id']?.toString() ?? map['rut']?.toString() ?? '',
        nombre: map['nombre']?.toString() ?? '',
        rut: map['rut']?.toString() ?? '',
        correo: map['correo']?.toString() ?? '',
        telefono: map['telefono']?.toString() ?? '',
        direccion: map['direccion']?.toString(),
      );
    }).toList();

    final Map<String, Cliente> mapaCombinado = {};

    for (var c in clientesRemotos) {
      final rutLimpio = c.rut.replaceAll('.', '').replaceAll('-', '').trim().toLowerCase();
      mapaCombinado[rutLimpio] = c;
    }
    for (var c in clientesPendientes) {
      final rutLimpio = c.rut.replaceAll('.', '').replaceAll('-', '').trim().toLowerCase();
      if (!mapaCombinado.containsKey(rutLimpio)) {
        mapaCombinado[rutLimpio] = c;
      }
    }
    for (var c in clientesEditados) {
      final rutLimpio = c.rut.replaceAll('.', '').replaceAll('-', '').trim().toLowerCase();
      mapaCombinado[rutLimpio] = c;
    }

    return mapaCombinado.values.toList();
  }

  @override
  Future<List<Cliente>> getClientes() async => await listarClientes();

  Future<bool> _hayConexion() async {
    final resultados = await Connectivity().checkConnectivity();
    return resultados.any((r) => r != ConnectivityResult.none);
  }

  @override
  Future<void> editarCliente(Cliente cliente) async {
    final dto = ClienteMapper.toDto(cliente);

    final hayConexion = await _hayConexion();
    if (!hayConexion) {
      await _localStorage.guardarClienteEditadoPendiente(dto.toMap());
      return;
    }

    try {
      await remoteDataSource.editarCliente(dto.id, dto);
    } catch (_) {
      await _localStorage.guardarClienteEditadoPendiente(dto.toMap());
    }
  }
  
  @override
  Future<void> eliminarCliente(String id) async {
    if (id.isEmpty) throw Exception('No se puede eliminar sin ID');
    await remoteDataSource.eliminarCliente(id);
  }
}