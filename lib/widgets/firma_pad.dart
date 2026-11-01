import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Recuadro para firmar con el dedo o el mouse. Exporta la firma como PNG con [FirmaPadState.exportar].
class FirmaPad extends StatefulWidget {
  final double alto;

  const FirmaPad({super.key, this.alto = 150});

  @override
  State<FirmaPad> createState() => FirmaPadState();
}

class FirmaPadState extends State<FirmaPad> {
  final List<List<Offset>> _trazos = [];
  Size _tamano = Size.zero;

  bool get vacia => _trazos.every((t) => t.length < 2);

  void limpiar() => setState(_trazos.clear);

  /// PNG de la firma con fondo transparente, o null si no se firmó.
  Future<Uint8List?> exportar() async {
    if (vacia || _tamano == Size.zero) return null;
    final grabadora = ui.PictureRecorder();
    final canvas = Canvas(grabadora);
    _PintorFirma(_trazos).paint(canvas, _tamano);
    final imagen = await grabadora.endRecording().toImage(_tamano.width.ceil(), _tamano.height.ceil());
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return datos?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.alto,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, c) {
            _tamano = Size(c.maxWidth, c.maxHeight);
            return Stack(
              children: [
                if (_trazos.isEmpty)
                  const Center(child: Text('Firma aquí', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 28,
                  child: Container(height: 1, color: AppTheme.border),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: (d) => setState(() => _trazos.add([d.localPosition])),
                    onPanUpdate: (d) => setState(() => _trazos.last.add(d.localPosition)),
                    child: CustomPaint(painter: _PintorFirma(_trazos)),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Borrar firma',
                    onPressed: limpiar,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PintorFirma extends CustomPainter {
  final List<List<Offset>> trazos;

  _PintorFirma(this.trazos);

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final trazo in trazos) {
      if (trazo.length < 2) continue;
      final camino = Path()..moveTo(trazo.first.dx, trazo.first.dy);
      for (final p in trazo.skip(1)) {
        camino.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(camino, pincel);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorFirma oldDelegate) => true;
}
