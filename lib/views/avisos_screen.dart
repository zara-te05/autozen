import 'package:flutter/material.dart';
import '../services/avisos_store.dart';
import '../services/sesion.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import '../widgets/animaciones.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/menu_lateral.dart';

/// Bandeja de avisos del rol actual (proyecto nuevo o editado, compras solicitadas o aprobadas).
class AvisosScreen extends StatefulWidget {
  const AvisosScreen({super.key});

  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  final AvisosStore _store = AvisosStore.instancia;
  late final Set<int> _nuevosAlAbrir;

  @override
  void initState() {
    super.initState();
    // Se recuerdan los nuevos para resaltarlos aunque al abrir se marquen como leídos
    _nuevosAlAbrir = _store.avisos.where(_store.esNuevo).map((a) => a.id).toSet();
    _store.marcarLeidos();
  }

  static IconData _icono(String tipo) => switch (tipo) {
        'proyecto_nuevo' => Icons.add_road,
        'proyecto_editado' => Icons.edit_note,
        'compra_solicitada' => Icons.shopping_cart_outlined,
        'compra_aprobada' => Icons.verified_outlined,
        _ => Icons.notifications_none,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const MenuLateral(seccion: Seccion.avisos),
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          if (!Sesion.modoDemo)
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Actualizar', onPressed: () => _store.cargar()),
        ],
      ),
      body: ContenidoResponsivo(
        anchoMaximo: 760,
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final avisos = _store.avisos;
            if (avisos.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No hay avisos.\nAquí llegarán los proyectos nuevos, cambios y compras que te correspondan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: avisos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = avisos[i];
                final nuevo = _nuevosAlAbrir.contains(a.id);
                return Aparicion(
                  indice: i,
                  child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: nuevo ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: nuevo ? AppTheme.info.withValues(alpha: 0.3) : AppTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_icono(a.tipo), color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(a.mensaje, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(formatearFechaHora(a.fecha), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
