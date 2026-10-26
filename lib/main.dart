import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'views/login_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/usuarios_screen.dart';
import 'views/departamentos_screen.dart';
import 'views/proyectos_screen.dart';
import 'views/compras_screen.dart';
import 'views/almacen_screen.dart';
import 'views/evaluacion_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AutozenApp());
}

class AutozenApp extends StatelessWidget {
  const AutozenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autösen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final rol = (args is String) ? args : 'admin';
          return DashboardScreen(rol: rol);
        },
        '/usuarios': (context) => const UsuariosScreen(),
        '/departamentos': (context) => const DepartamentosScreen(),
        '/proyectos': (context) => const ProyectosScreen(),
        '/compras': (context) => const ComprasScreen(),
        '/almacen': (context) => const AlmacenScreen(),
        '/evaluacion': (context) => const EvaluacionScreen(),
      },
    );
  }
}
