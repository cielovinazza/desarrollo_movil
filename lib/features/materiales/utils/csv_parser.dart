import 'package:project/features/materiales/domain/entities/material.dart';

class ResultadoCSV {
  final List<MaterialEntity> materialesValidos;
  final List<String> filasRechazadas;

  ResultadoCSV({
    required this.materialesValidos,
    required this.filasRechazadas,
  });
}

ResultadoCSV parsearCSV(String contenido) {
  final lineas = contenido
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (lineas.isEmpty) {
    return ResultadoCSV(
      materialesValidos: [],
      filasRechazadas: ['El archivo CSV está vacío'],
    );
  }

  final encabezados = lineas.first
      .split(RegExp(r',|;'))
      .map((h) => h.trim())
      .toList();

  final idxNombre = encabezados.indexWhere((h) => h == 'Nombre_Material');

  final idxUnidad = encabezados.indexWhere((h) => h == 'Unidad_Medida');

  final idxCosto = encabezados.indexWhere((h) => h == 'Costo_Unitario_CLP');

  if (idxNombre == -1 || idxUnidad == -1 || idxCosto == -1) {
    return ResultadoCSV(
      materialesValidos: [],
      filasRechazadas: [
        'Encabezado inválido: se requieren '
            'Nombre_Material, '
            'Unidad_Medida, '
            'Costo_Unitario_CLP',
      ],
    );
  }

  final validos = <MaterialEntity>[];
  final rechazadas = <String>[];

  for (int i = 1; i < lineas.length; i++) {
    final celdas = lineas[i]
        .split(RegExp(r',|;'))
        .map((c) => c.trim())
        .toList();

    final numFila = i + 1;

    if (celdas.length <= idxNombre ||
        celdas.length <= idxUnidad ||
        celdas.length <= idxCosto) {
      rechazadas.add('Fila $numFila: columnas insuficientes');
      continue;
    }

    final nombre = celdas[idxNombre].trim();
    final unidad = celdas[idxUnidad].trim();
    final costoStr = celdas[idxCosto].trim();

    if (nombre.isEmpty) {
      rechazadas.add('Fila $numFila: el campo Nombre_Material está vacío');
      continue;
    }
    if (unidad.isEmpty) {
      rechazadas.add('Fila $numFila: el campo Unidad_Medida está vacío');
      continue;
    }
    if (costoStr.isEmpty) {
      rechazadas.add('Fila $numFila: el campo Costo_Unitario_CLP está vacío');
      continue;
    }

    final costo = double.tryParse(costoStr);

    if (costo == null) {
      rechazadas.add('Fila $numFila: "$costoStr" no es un valor numérico');
      continue;
    }

    if (costo <= 0) {
      rechazadas.add(
        'Fila $numFila: costo debe ser mayor a cero '
        '(valor: $costoStr)',
      );
      continue;
    }

    if (costo % 1 != 0) {
      rechazadas.add('Fila $numFila: el costo debe ser un número entero');
      continue;
    }

    validos.add(
      MaterialEntity(
        nombre: nombre,
        unidadMedida: unidad,
        costoUnitario: costo,
        cantidad: 1,
      ),
    );
  }

  return ResultadoCSV(materialesValidos: validos, filasRechazadas: rechazadas);
}
