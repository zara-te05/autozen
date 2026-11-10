/// Reglas de contraseña (las mismas que valida el backend):
/// 8 a 64 caracteres, solo letras y números (sin espacios, acentos ni signos),
/// con al menos una letra y un número.
final RegExp _passwordValida = RegExp(r'^(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9]{8,64}$');

const String reglaPassword = '8 a 64 caracteres, solo letras y números, al menos una letra y un número';

/// Devuelve el mensaje de error, o null si la contraseña es válida.
/// Con [opcional] una contraseña vacía es válida (al editar: conserva la actual).
String? validarPassword(String? password, {bool opcional = false}) {
  final texto = password ?? '';
  if (texto.isEmpty) return opcional ? null : 'Ingresa la contraseña.';
  if (texto.contains(RegExp(r'\s'))) return 'La contraseña no puede tener espacios.';
  if (texto.length < 8) return 'Mínimo 8 caracteres.';
  if (texto.length > 64) return 'Máximo 64 caracteres.';
  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(texto)) return 'Solo letras y números (sin acentos, ñ ni signos).';
  if (!_passwordValida.hasMatch(texto)) return 'Debe tener al menos una letra y un número.';
  return null;
}
