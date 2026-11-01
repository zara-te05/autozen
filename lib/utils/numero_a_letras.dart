/// Convierte un importe a letra como en las órdenes de compra:
/// 917.56 → "Novecientos diecisiete pesos 56/100 M.N."
String importeConLetra(double monto) {
  final totalCentavos = (monto.abs() * 100).round();
  final entero = totalCentavos ~/ 100;
  final centavos = totalCentavos % 100;

  var letras = entero == 0 ? 'cero' : _apocopar(_numero(entero));
  if (entero >= 1000000 && entero % 1000000 == 0) letras = '$letras de';
  final moneda = entero == 1 ? 'peso' : 'pesos';
  final texto = '$letras $moneda ${centavos.toString().padLeft(2, '0')}/100 M.N.';
  return texto[0].toUpperCase() + texto.substring(1);
}

const _unidades = ['', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve'];
const _diezA29 = [
  'diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho', 'diecinueve',
  'veinte', 'veintiuno', 'veintidós', 'veintitrés', 'veinticuatro', 'veinticinco', 'veintiséis', 'veintisiete', 'veintiocho', 'veintinueve',
];
const _decenas = ['', '', '', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta', 'ochenta', 'noventa'];
const _centenas = ['', 'ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos', 'seiscientos', 'setecientos', 'ochocientos', 'novecientos'];

/// "uno" delante de un sustantivo se acorta: veintiuno → veintiún, treinta y uno → treinta y un.
String _apocopar(String texto) {
  if (texto.endsWith('veintiuno')) return '${texto.substring(0, texto.length - 9)}veintiún';
  if (texto.endsWith('uno')) return '${texto.substring(0, texto.length - 3)}un';
  return texto;
}

String _numero(int n) {
  if (n >= 1000000) {
    final millones = n ~/ 1000000;
    final resto = n % 1000000;
    final parte = millones == 1 ? 'un millón' : '${_apocopar(_numero(millones))} millones';
    return resto == 0 ? parte : '$parte ${_numero(resto)}';
  }
  if (n >= 1000) {
    final miles = n ~/ 1000;
    final resto = n % 1000;
    final parte = miles == 1 ? 'mil' : '${_apocopar(_numero(miles))} mil';
    return resto == 0 ? parte : '$parte ${_numero(resto)}';
  }
  if (n >= 100) {
    if (n == 100) return 'cien';
    final resto = n % 100;
    return resto == 0 ? _centenas[n ~/ 100] : '${_centenas[n ~/ 100]} ${_numero(resto)}';
  }
  if (n >= 30) {
    final u = n % 10;
    return u == 0 ? _decenas[n ~/ 10] : '${_decenas[n ~/ 10]} y ${_unidades[u]}';
  }
  if (n >= 10) return _diezA29[n - 10];
  return _unidades[n];
}
