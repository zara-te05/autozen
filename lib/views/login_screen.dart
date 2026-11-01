import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Importante para la navegación
import '../services/api_client.dart';
import '../services/sesion.dart';

/// Cuentas de prueba que entran SIN llamar a la API. Solo existen en modo debug
/// (`flutter run`); en una compilación release (`flutter build`) quedan desactivadas.
const Map<String, ({String password, String rol})> _cuentasDePrueba = {
  'admin@prueba.com': (password: 'prueba123', rol: 'Admin'),
  'encargado@prueba.com': (password: 'prueba123', rol: 'Proyecto_Lider'),
  'compras@prueba.com': (password: 'prueba123', rol: 'Compras_Admin'),
  'almacen@prueba.com': (password: 'prueba123', rol: 'Almacen_Admin'),
  'evaluacion@prueba.com': (password: 'prueba123', rol: 'Evaluacion_Admin'),
};

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSplash = true;
  bool _isLoading = false;
  bool _ocultarPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isSplash = false;
          });
        }
      });
    });
  }

  void _mostrarRecuperacionContrasena() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recuperar contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Por políticas de seguridad, para restablecer tu acceso debes contactar al Product Owner o al administrador del sistema de Autösen.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _iniciarSesion() async {
    FocusScope.of(context).unfocus(); 

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu correo y contraseña.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? rolBackend;
    String mensajeError = 'Credenciales incorrectas. Intenta de nuevo.';
    String? avisoSincronizacion;
    final cuentaPrueba = !kReleaseMode ? _cuentasDePrueba[email.toLowerCase()] : null;
    if (cuentaPrueba != null && cuentaPrueba.password == password) {
      // Modo demo: no se contacta al backend, todo en memoria con datos de ejemplo
      rolBackend = cuentaPrueba.rol;
      Sesion.iniciarDemo(rol: cuentaPrueba.rol);
    } else {
      try {
        final respuesta = await ApiClient().login(email, password);
        rolBackend = respuesta['rol'] as String?;
        avisoSincronizacion = await Sesion.iniciarConApi(respuesta);
      } on ApiException catch (e) {
        if (e.status == 429) {
          mensajeError = 'Demasiados intentos. Espera un minuto e intenta de nuevo.';
        } else if (e.status != 401) {
          mensajeError = e.mensaje;
        }
      }
    }

    if (rolBackend == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final bool esAdmin = rolBackend == 'Admin';

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSplash = true; 
      });
    }

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted && avisoSincronizacion != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesión iniciada, pero no se pudo cargar todo: $avisoSincronizacion')),
      );
    }

    if (mounted) {
      String rolAsignado = esAdmin ? 'admin' : 'encargado';

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => DashboardScreen(rol: rolAsignado),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(top: size.height * 0.35, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Iniciar Sesión', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 24),
                const Text('Correo electrónico', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'ejemplo@autosen.com',
                    hintStyle: const TextStyle(color: Colors.black26),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _ocultarPassword,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: Colors.black26),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _ocultarPassword = !_ocultarPassword;
                        });
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _mostrarRecuperacionContrasena,
                    child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _iniciarSesion,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 55,
                      width: _isLoading ? 55 : size.width,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(_isLoading ? 30 : 25)),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOutCubic,
            height: _isSplash ? size.height : size.height * 0.3,
            width: _isSplash ? size.width : size.width * 0.95,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(_isSplash ? 0 : 200)),
            ),
            child: SafeArea(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOutCubic,
                alignment: _isSplash ? Alignment.center : Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: _isSplash ? 0 : 24, top: _isSplash ? 0 : 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: _isSplash ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      const Text('AUTÖSEN', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4.0)),
                      if (!_isSplash) ...[
                        const SizedBox(height: 8),
                        const Text('Bienvenido de vuelta. Inicia sesión para continuar.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}