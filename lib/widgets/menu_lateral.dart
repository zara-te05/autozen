import 'package:flutter/material.dart';
import '../models/catalogos.dart';
import '../models/proyecto_taller.dart';
import '../services/avisos_store.dart';
import '../services/compras_store.dart';
import '../services/sesion.dart';
import '../utils/app_theme.dart';
import '../views/almacen_screen.dart';
import '../views/avisos_screen.dart';
import '../views/compras_screen.dart';
import '../views/departamentos_screen.dart';
import '../views/evaluacion_screen.dart';
import '../views/login_screen.dart';
import '../views/proveedores_screen.dart';
import '../views/proyectos_screen.dart';
import '../views/usuarios_screen.dart';

enum Seccion { usuarios, departamentos, evaluacion, proyectosClientes, proyectosAseguradora, compras, almacen, proveedores, avisos }

/// Menú hamburguesa disponible en todos los apartados, para pasar de uno a otro sin volver al inicio.
///
/// Siempre deja el menú principal como pantalla raíz: el botón "atrás" de cualquier apartado regresa al inicio.
class MenuLateral extends StatelessWidget {
  final Seccion seccion;

  const MenuLateral({super.key, required this.seccion});

  void _ir(BuildContext context, Seccion destino) {
    final navegador = Navigator.of(context);
    navegador.pop(); // cierra el menú
    if (destino == seccion) return;
    final Widget pantalla = switch (destino) {
      Seccion.usuarios => const UsuariosScreen(),
      Seccion.departamentos => const DepartamentosScreen(),
      Seccion.evaluacion => const EvaluacionScreen(),
      Seccion.proyectosClientes => const ProyectosScreen(tipo: TipoProyecto.cliente),
      Seccion.proyectosAseguradora => const ProyectosScreen(tipo: TipoProyecto.aseguradora),
      Seccion.compras => const ComprasScreen(),
      Seccion.almacen => const AlmacenScreen(),
      Seccion.proveedores => const ProveedoresScreen(),
      Seccion.avisos => const AvisosScreen(),
    };
    // Reemplaza el apartado actual y conserva el menú principal debajo
    navegador.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => pantalla,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
      (route) => route.isFirst,
    );
  }

  void _inicio(BuildContext context) {
    final navegador = Navigator.of(context);
    navegador.pop();
    navegador.popUntil((route) => route.isFirst);
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Seguro que deseas salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (salir != true || !context.mounted) return;
    Sesion.cerrar();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              color: AppTheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AUTÖSEN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text(
                    Sesion.nombre.isEmpty ? 'Usuario' : Sesion.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(rolesSistema[Sesion.rol] ?? Sesion.rol, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _opcion(context, null, 'Inicio', Icons.home_outlined, onTap: () => _inicio(context)),
                  const Divider(height: 16),
                  if (Sesion.esAdmin) ...[
                    _opcion(context, Seccion.usuarios, 'Usuarios', Icons.people_outline),
                    _opcion(context, Seccion.departamentos, 'Departamentos', Icons.business_outlined),
                  ],
                  _opcion(context, Seccion.evaluacion, 'Evaluación de Daños', Icons.fact_check_outlined),
                  _opcion(context, Seccion.proyectosClientes, 'Proyectos de Clientes', Icons.folder_open),
                  _opcion(context, Seccion.proyectosAseguradora, 'Proyectos de Aseguradora', Icons.verified_user_outlined),
                  _opcion(context, Seccion.compras, 'Compras', Icons.shopping_bag_outlined, contador: ComprasStore.instancia.pendientes.length),
                  _opcion(context, Seccion.almacen, 'Almacén', Icons.inventory_2_outlined),
                  _opcion(context, Seccion.proveedores, 'Proveedores', Icons.storefront_outlined),
                  const Divider(height: 16),
                  _opcion(context, Seccion.avisos, 'Avisos', Icons.notifications_none, contador: AvisosStore.instancia.noLeidos),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () => _cerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcion(BuildContext context, Seccion? destino, String titulo, IconData icono, {VoidCallback? onTap, int contador = 0}) {
    final bool actual = destino == seccion;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: actual,
        selectedTileColor: const Color(0xFFF1F2F4),
        selectedColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icono, color: actual ? AppTheme.primary : AppTheme.textSecondary),
        title: Text(titulo, style: TextStyle(fontWeight: actual ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
        trailing: contador > 0
            ? Badge(label: Text(contador > 9 ? '9+' : '$contador'), backgroundColor: AppTheme.danger)
            : null,
        onTap: onTap ?? () => _ir(context, destino!),
      ),
    );
  }
}
