import 'dart:async';
import 'package:flutter/material.dart';

/// Aparece con un fundido y un pequeño deslizamiento hacia arriba.
/// Con [indice] se escalona: útil en listas y cuadrículas (cada elemento entra un poco después del anterior).
/// Respeta la opción de accesibilidad "quitar animaciones" del sistema.
class Aparicion extends StatefulWidget {
  final Widget child;
  final int indice;
  final Duration duracion;
  final double desplazamiento;

  const Aparicion({
    super.key,
    required this.child,
    this.indice = 0,
    this.duracion = const Duration(milliseconds: 420),
    this.desplazamiento = 16,
  });

  @override
  State<Aparicion> createState() => _AparicionState();
}

class _AparicionState extends State<Aparicion> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(vsync: this, duration: widget.duracion);
  late final Animation<double> _curva = CurvedAnimation(parent: _controlador, curve: Curves.easeOutCubic);
  Timer? _retraso;

  @override
  void initState() {
    super.initState();
    // Máximo ~0.4 s de espera aunque la lista sea larga
    final espera = Duration(milliseconds: 45 * widget.indice.clamp(0, 9));
    if (espera == Duration.zero) {
      _controlador.forward();
    } else {
      _retraso = Timer(espera, () {
        if (mounted) _controlador.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _retraso?.cancel();
      _controlador.value = 1;
    }
  }

  @override
  void dispose() {
    _retraso?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curva,
      child: AnimatedBuilder(
        animation: _curva,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _curva.value) * widget.desplazamiento),
          child: child,
        ),
      ),
    );
  }
}

/// Se encoge un poco al tocarlo y crece apenas al pasar el mouse encima (Windows).
/// No intercepta los toques: el InkWell o botón de adentro sigue funcionando igual.
class Presionable extends StatefulWidget {
  final Widget child;
  final double escalaPresionado;
  final double escalaEncima;

  const Presionable({super.key, required this.child, this.escalaPresionado = 0.96, this.escalaEncima = 1.02});

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;
  bool _encima = false;

  void _presion(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final escala = _presionado ? widget.escalaPresionado : (_encima ? widget.escalaEncima : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() {
        _encima = false;
        _presionado = false;
      }),
      child: Listener(
        onPointerDown: (_) => _presion(true),
        onPointerUp: (_) => _presion(false),
        onPointerCancel: (_) => _presion(false),
        child: AnimatedScale(
          scale: escala,
          duration: Duration(milliseconds: _presionado ? 90 : 180),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Cambia de contenido con un fundido y ajusta su altura suavemente
/// (p. ej. de "no hay elementos" a la lista, o al agregar o quitar uno).
class CambioSuave extends StatelessWidget {
  final Widget child;
  const CambioSuave({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (actual, anteriores) => Stack(alignment: Alignment.topCenter, fit: StackFit.passthrough, children: [...anteriores, ?actual]),
        child: child,
      ),
    );
  }
}
