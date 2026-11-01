import 'package:flutter/material.dart';

/// Limita el ancho del contenido y lo centra. Evita que en ventanas anchas (Windows)
/// los formularios y tarjetas se estiren de lado a lado. En teléfono no cambia nada.
class ContenidoResponsivo extends StatelessWidget {
  final Widget child;
  final double anchoMaximo;

  const ContenidoResponsivo({super.key, required this.child, this.anchoMaximo = 900});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
