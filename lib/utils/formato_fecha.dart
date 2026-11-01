const List<String> _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

/// Formato corto en español: 12/Oct/2026
String formatearFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  return '$dia/${_meses[fecha.month - 1]}/${fecha.year}';
}

/// 12/Oct/2026 14:05
String formatearFechaHora(DateTime fecha) {
  final hora = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  return '${formatearFecha(fecha)} $hora';
}

/// $ 1,234.50
String formatearDinero(double monto) {
  final partes = monto.toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '\$ $entero.${partes[1]}';
}
