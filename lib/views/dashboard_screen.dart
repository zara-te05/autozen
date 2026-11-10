import 'package:flutter/material.dart';
import 'login_screen.dart'; // Importante para poder regresar al Login
import '../services/sesion.dart';
import '../services/avisos_store.dart';
import 'avisos_screen.dart';
import 'evaluacion_screen.dart'; 
import 'usuarios_screen.dart';
import 'almacen_screen.dart';
import 'proyectos_screen.dart';
import '../models/proyecto_taller.dart';
import 'compras_screen.dart';
import 'departamentos_screen.dart'; 
import 'proveedores_screen.dart';
import '../services/tablero_store.dart';
import '../widgets/animaciones.dart';
import '../widgets/tablero_inicio.dart';

class DashboardScreen extends StatefulWidget {
  final String rol;
  const DashboardScreen({super.key, required this.rol});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isExpanded = true; 
  bool _sincronizando = false;

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    final error = await Sesion.sincronizar();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Datos actualizados.'),
        backgroundColor: error == null ? Colors.green.shade700 : Colors.redAccent,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  // ----------------------------------------------------
  // DIÁLOGO DE CONFIRMACIÓN PARA CERRAR SESIÓN
  // ----------------------------------------------------
  void _mostrarDialogoCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta? Tendrás que volver a ingresar tus credenciales.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cierra el diálogo sin hacer nada
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo primero
              Sesion.cerrar(); // Borra el token y regresa los datos al modo demo
              // Navega al Login y DESTRUYE el historial de pantallas anterior
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                  transitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Regresamos con un fundido suave
                    return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
                  },
                ),
                (Route<dynamic> route) => false, 
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, // Rojo para advertir la salida
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Salir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final String tituloVista = Sesion.descripcionVista;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      body: Stack(
        children: [
          // CAPA INFERIOR: El Menú de Tarjetas
          Column(
            children: [
              const SizedBox(height: 260),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final error = await TableroStore.instancia.cargar();
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
                    }
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Primero el tablero: entregas de la semana, coordinación del día y anuncios
                      const SliverPadding(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                        sliver: SliverToBoxAdapter(child: TableroInicio()),
                      ),
                      // Tarjetas de ancho máximo fijo: 2 columnas en teléfono, más columnas en ventanas anchas
                      SliverPadding(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                        sliver: SliverGrid.extent(
                          maxCrossAxisExtent: 240,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.95,
                          children: [
                            // Entran una tras otra, después del tablero
                            for (final (i, tarjeta) in _generarTarjetasSegunRol(context).indexed) Aparicion(indice: i + 3, child: tarjeta),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // CAPA SUPERIOR: La cabecera negra
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOutCubic,
            height: _isExpanded ? size.height : 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(_isExpanded ? 0 : 80),
                bottomLeft: Radius.circular(_isExpanded ? 0 : 20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW AÑADIDO: Título a la izquierda, Botón de Salir a la derecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AUTÖSEN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                        const Spacer(),
                        if (Sesion.modoDemo)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                            child: const Text('MODO DEMO', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          IconButton(
                            onPressed: _sincronizando ? null : _sincronizar,
                            icon: _sincronizando
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                                : const Icon(Icons.sync, color: Colors.white70),
                            tooltip: 'Actualizar datos del servidor',
                          ),
                        ListenableBuilder(
                          listenable: AvisosStore.instancia,
                          builder: (context, _) {
                            final n = AvisosStore.instancia.noLeidos;
                            return IconButton(
                              tooltip: 'Avisos',
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AvisosScreen())),
                              icon: Badge(
                                isLabelVisible: n > 0,
                                label: Text(n > 9 ? '9+' : '$n'),
                                child: const Icon(Icons.notifications_none, color: Colors.white70),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () => _mostrarDialogoCerrarSesion(context),
                          icon: const Icon(Icons.logout, color: Colors.white70),
                          tooltip: 'Cerrar sesión',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Margen ajustado
                    // Se reduce si no cabe, en vez de partirse en dos líneas y salirse de la cabecera
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(tituloVista, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¿Qué área vamos a gestionar hoy?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generarTarjetasSegunRol(BuildContext context) {
    List<Widget> tarjetas = [];

    // Cada quien ve solo las áreas que puede leer (Admin y jefes: todas; un Usuario: la suya)
    if (Sesion.gestionaUsuarios) {
      tarjetas.add(_buildMenuCard(context, 'Usuarios', Icons.people_outline, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UsuariosScreen()));
      }));
    }
    if (Sesion.esAdmin) {
      tarjetas.add(_buildMenuCard(context, 'Departamentos', Icons.business_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DepartamentosScreen()));
      }));
    }

    // El primer paso siempre es evaluar el daño; de ahí nace el proyecto
    if (Sesion.veEvaluacion && Sesion.creaProyectos) {
      tarjetas.add(_buildMenuCard(context, 'Evaluación de Daños', Icons.fact_check_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EvaluacionScreen()));
      }));
    }
    if (Sesion.veProyectos) {
      tarjetas.add(_buildMenuCard(context, 'Proyectos de Clientes', Icons.folder_open, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProyectosScreen(tipo: TipoProyecto.cliente)));
      }));
      tarjetas.add(_buildMenuCard(context, 'Proyectos de Aseguradora', Icons.verified_user_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProyectosScreen(tipo: TipoProyecto.aseguradora)));
      }));
    }
    if (Sesion.veCompras) {
      tarjetas.add(_buildMenuCard(context, 'Compras', Icons.shopping_bag_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ComprasScreen()));
      }));
    }
    if (Sesion.veAlmacen) {
      tarjetas.add(_buildMenuCard(context, 'Almacén', Icons.inventory_2_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AlmacenScreen()));
      }));
    }
    if (Sesion.veCompras) {
      tarjetas.add(_buildMenuCard(context, 'Proveedores', Icons.storefront_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProveedoresScreen()));
      }));
    }

    return tarjetas;
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, VoidCallback onTap) =>
      _TarjetaMenu(titulo: title, icono: icon, onTap: onTap);
}

/// Tarjeta de área del dashboard: se encoge al tocarla y, con el mouse encima,
/// se eleva, el ícono se vuelve negro y la flecha avanza.
class _TarjetaMenu extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final VoidCallback onTap;

  const _TarjetaMenu({required this.titulo, required this.icono, required this.onTap});

  @override
  State<_TarjetaMenu> createState() => _TarjetaMenuState();
}

class _TarjetaMenuState extends State<_TarjetaMenu> {
  bool _activa = false;

  static const _duracion = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return Presionable(
      escalaEncima: 1.0, // La elevación ya marca el hover; solo se encoge al tocar
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _activa = true),
        onExit: (_) => setState(() => _activa = false),
        child: AnimatedContainer(
          duration: _duracion,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _activa ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _activa ? Colors.black12 : Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _activa ? 0.10 : 0.04),
                blurRadius: _activa ? 24 : 15,
                offset: Offset(0, _activa ? 12 : 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              splashColor: Colors.black.withValues(alpha: 0.05),
              highlightColor: Colors.black.withValues(alpha: 0.02),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: _duracion,
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _activa ? Colors.black : Colors.grey.shade100, shape: BoxShape.circle),
                      child: TweenAnimationBuilder<Color?>(
                        duration: _duracion,
                        tween: ColorTween(end: _activa ? Colors.white : Colors.black87),
                        builder: (context, color, _) => Icon(widget.icono, size: 28, color: color),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black, height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSlide(
                      duration: _duracion,
                      curve: Curves.easeOutCubic,
                      offset: Offset(_activa ? 0.35 : 0, 0),
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: _activa ? Colors.black87 : Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
