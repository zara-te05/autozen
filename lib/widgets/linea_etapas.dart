import 'package:flutter/material.dart';
import '../models/proyecto_taller.dart';
import '../utils/app_theme.dart';

/// Línea de tiempo de etapas. Se reparte en el ancho disponible y, si hay demasiadas
/// etapas para que se lean, permite desplazarse horizontalmente.
class LineaEtapas extends StatelessWidget {
  final List<EtapaProyecto> etapas;

  /// Índice de la etapa en curso; igual a `etapas.length` cuando ya terminaron todas.
  final int etapaActual;

  const LineaEtapas({super.key, required this.etapas, required this.etapaActual});

  static const double _anchoMinimoPaso = 84;
  static const Color _gris = Color(0xFFE4E4E7);

  @override
  Widget build(BuildContext context) {
    if (etapas.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final int total = etapas.length;
        final bool cabe = total * _anchoMinimoPaso <= constraints.maxWidth;
        final double anchoPaso = cabe ? constraints.maxWidth / total : _anchoMinimoPaso;

        final fila = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < total; i++) SizedBox(width: anchoPaso, child: _buildPaso(i, total)),
          ],
        );

        return cabe ? fila : SingleChildScrollView(scrollDirection: Axis.horizontal, child: fila);
      },
    );
  }

  Widget _buildPaso(int i, int total) {
    final bool completado = i < etapaActual;
    final bool actual = i == etapaActual;
    final bool alcanzado = completado || actual;

    return Column(
      children: [
        // Las líneas comparten fila con el círculo, así quedan alineadas a su centro
        SizedBox(
          height: 24,
          child: Row(
            children: [
              Expanded(
                child: i == 0 ? const SizedBox.shrink() : Container(height: 2, color: alcanzado ? AppTheme.primary : _gris),
              ),
              CircleAvatar(
                radius: actual ? 12 : 9,
                backgroundColor: alcanzado ? AppTheme.primary : _gris,
                child: completado
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : actual
                        ? Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                        : null,
              ),
              Expanded(
                child: i == total - 1 ? const SizedBox.shrink() : Container(height: 2, color: completado ? AppTheme.primary : _gris),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            etapas[i].nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: actual ? FontWeight.bold : FontWeight.normal,
              color: actual ? AppTheme.primary : AppTheme.textMuted,
            ),
          ),
        ),
        Text(
          '${etapas[i].diasEstimados} ${etapas[i].diasEstimados == 1 ? 'día' : 'días'}',
          style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
