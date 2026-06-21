extension StringCapitalization on String {
  String toTitleCase() {
    if (trim().isEmpty) return '';

    return trim()
        .split(RegExp(r'\s+'))
        .map((palabra) {
          if (palabra.isEmpty) return '';
          // Toma la primera letra en mayúscula y el resto en minúscula
          return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
        })
        .join(' ');
  }
}