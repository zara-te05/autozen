import 'package:flutter/material.dart';

/// Transición única de la app: la pantalla nueva aparece con un fundido y un ligero deslizamiento hacia arriba,
/// y la anterior se aleja un poco. Se aplica a toda navegación con MaterialPageRoute (ver AppTheme)
/// y a las rutas creadas con [rutaSuave].
class TransicionSuaveBuilder extends PageTransitionsBuilder {
  const TransicionSuaveBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      transicionSuave(animation, secondaryAnimation, child);
}

Widget transicionSuave(Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  final entrada = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
  final salida = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
  return FadeTransition(
    opacity: entrada,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(entrada),
      // La pantalla que queda debajo se aleja un poco mientras entra la nueva
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.97).animate(salida),
        child: child,
      ),
    ),
  );
}

/// Ruta con la transición de la app y duración configurable.
Route<T> rutaSuave<T>(Widget pagina, {Duration duracion = const Duration(milliseconds: 360)}) => PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => pagina,
      transitionDuration: duracion,
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => transicionSuave(animation, secondaryAnimation, child),
    );
