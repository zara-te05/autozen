import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Aviso que reemplaza un formulario cuando el perfil solo puede consultar.
class AvisoSoloLectura extends StatelessWidget {
  final String texto;
  const AvisoSoloLectura(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 20, color: AppTheme.info),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.35))),
        ],
      ),
    );
  }
}
