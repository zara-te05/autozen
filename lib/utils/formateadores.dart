import 'package:flutter/services.dart';

/// Convierte lo que se escribe a mayúsculas (placas, folios).
class MayusculasFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Formateadores estándar para un campo de placa.
List<TextInputFormatter> get formateadoresPlaca => [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\- ]')),
      LengthLimitingTextInputFormatter(12),
      MayusculasFormatter(),
    ];
