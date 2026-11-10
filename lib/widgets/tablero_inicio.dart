import 'package:flutter/material.dart';
import '../models/tablero.dart';
import '../services/proyectos_store.dart';
import '../services/sesion.dart';
import '../services/tablero_store.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import 'animaciones.dart';
import 'confirm_dialog.dart';

/// Tablero que aparece arriba de las tarjetas del dashboard:
/// 1. Programación de entregas de unidades de la semana (salen de los proyectos; el Admin agrega o quita).
/// 2. Coordinación operativa del día (post-its; se borran a las 7 pm).
/// 3. Anuncios.
/// Todos lo ven; solo el Admin puede agregar, editar, eliminar y quitar proyectos del tablero.
class TableroInicio extends StatelessWidget {
  const TableroInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // En modo demo las entregas se calculan de los proyectos en memoria
      listenable: Listenable.merge([TableroStore.instancia, ProyectosStore.instancia]),
      builder: (context, _) {
        final store = TableroStore.instancia;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Las secciones entran una tras otra al abrir el dashboard
            Aparicion(indice: 0, child: _SeccionEntregas(entregas: store.entregas)),
            const SizedBox(height: 24),
            Aparicion(indice: 1, child: _SeccionCoordinacion(notas: store.coordinacion)),
            const SizedBox(height: 24),
            Aparicion(indice: 2, child: _SeccionAnuncios(anuncios: store.anuncios)),
            const SizedBox(height: 28),
            const Aparicion(
              indice: 3,
              child: Text('Áreas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

// =====================================================================
// Piezas comunes
// =====================================================================

const List<String> _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const List<String> _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

String _rangoSemana() {
  final i = TableroStore.inicioSemana;
  final f = TableroStore.finSemana;
  return i.month == f.month ? '${i.day} – ${f.day} ${_meses[f.month - 1]}' : '${i.day} ${_meses[i.month - 1]} – ${f.day} ${_meses[f.month - 1]}';
}

void _mostrarResultado(BuildContext context, String? error, String exito) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(error ?? exito),
    backgroundColor: error == null ? Colors.green.shade700 : Colors.redAccent,
  ));
}

class _EncabezadoSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String textoAgregar;
  final VoidCallback onAgregar;

  const _EncabezadoSeccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.textoAgregar,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icono, size: 22, color: AppTheme.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(subtitulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (Sesion.esAdmin)
            TextButton.icon(
              onPressed: onAgregar,
              icon: const Icon(Icons.add, size: 18),
              label: Text(textoAgregar),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary, textStyle: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String texto;
  const _Vacio(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    );
  }
}

/// Menú ⋮ de editar / eliminar (solo Admin).
class _MenuAdmin extends StatelessWidget {
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final List<PopupMenuEntry<String>> extras;
  final void Function(String)? onExtra;
  final Color? color;

  /// Sin "Editar" ni "Eliminar" (p. ej. entregas que salen de un proyecto).
  final bool soloExtras;

  const _MenuAdmin({
    required this.onEditar,
    required this.onEliminar,
    this.extras = const [],
    this.onExtra,
    this.color,
    this.soloExtras = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!Sesion.esAdmin) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      icon: Icon(Icons.more_vert, size: 20, color: color ?? AppTheme.textSecondary),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'editar') {
          onEditar();
        } else if (v == 'eliminar') {
          onEliminar();
        } else {
          onExtra?.call(v);
        }
      },
      itemBuilder: (_) => [
        ...extras,
        if (!soloExtras) ...[
          const PopupMenuItem(value: 'editar', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'), dense: true, contentPadding: EdgeInsets.zero)),
          const PopupMenuItem(
            value: 'eliminar',
            child: ListTile(leading: Icon(Icons.delete_outline, color: AppTheme.danger), title: Text('Eliminar', style: TextStyle(color: AppTheme.danger)), dense: true, contentPadding: EdgeInsets.zero),
          ),
        ],
      ],
    );
  }
}

Future<bool> _confirmarEliminar(BuildContext context, String que) => ConfirmDialog.show(
      context: context,
      title: 'Eliminar $que',
      message: '¿Seguro que deseas eliminar $que? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

InputDecoration _campo(String etiqueta, {String? ayuda}) => InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

// =====================================================================
// 1. Entregas de la semana
// =====================================================================

class _SeccionEntregas extends StatelessWidget {
  final List<EntregaSemana> entregas;
  const _SeccionEntregas({required this.entregas});

  @override
  Widget build(BuildContext context) {
    final visibles = entregas.where((e) => !e.oculta).toList();
    final pendientes = visibles.where((e) => !e.entregada).length;
    final ocultas = entregas.length - visibles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EncabezadoSeccion(
          icono: Icons.local_shipping_outlined,
          titulo: 'Entregas de la semana',
          subtitulo: '${_rangoSemana()} · ${visibles.isEmpty ? 'sin unidades por entregar' : '$pendientes pendiente${pendientes == 1 ? '' : 's'} de ${visibles.length}'}'
              '${ocultas > 0 ? ' · $ocultas quitada${ocultas == 1 ? '' : 's'} del tablero' : ''}',
          textoAgregar: 'Agregar',
          onAgregar: () => _editarEntrega(context, null),
        ),
        CambioSuave(
          child: entregas.isEmpty
              ? const _Vacio('Ningún proyecto se entrega esta semana.')
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < entregas.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                        _FilaEntrega(key: ValueKey('${entregas[i].origen}-${entregas[i].id}'), entrega: entregas[i]),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilaEntrega extends StatelessWidget {
  final EntregaSemana entrega;
  const _FilaEntrega({super.key, required this.entrega});

  @override
  Widget build(BuildContext context) {
    final hoy = soloFecha(DateTime.now());
    final esHoy = entrega.fechaEntrega == hoy;
    final atrasada = !entrega.entregada && entrega.fechaEntrega.isBefore(hoy);

    final (String estado, Color colorEstado) = entrega.oculta
        ? ('Quitada', AppTheme.textMuted)
        : entrega.entregada
        ? (entrega.esProyecto ? 'Terminado' : 'Entregada', AppTheme.success)
        : atrasada
            ? ('Atrasada', AppTheme.danger)
            : esHoy
                ? ('Hoy', AppTheme.warning)
                : ('Pendiente', AppTheme.info);

    final detalle = [
      if (entrega.codigo != null) entrega.codigo!,
      if (entrega.cliente != null && entrega.cliente!.isNotEmpty) entrega.cliente!,
      if (entrega.notas != null && entrega.notas!.isNotEmpty) entrega.notas!,
    ].join(' · ');

    final menuAdmin = !Sesion.esAdmin
        ? const SizedBox(width: 8)
        : entrega.esProyecto
            // Las entregas de proyectos no se editan aquí (se editan en el proyecto): solo se quitan o regresan
            ? _MenuAdmin(
                soloExtras: true,
                extras: [
                  PopupMenuItem(
                    value: 'ocultar',
                    child: ListTile(
                      leading: Icon(entrega.oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      title: Text(entrega.oculta ? 'Regresar al tablero' : 'Quitar del tablero'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onExtra: (_) async {
                  final store = TableroStore.instancia;
                  final error = await (entrega.oculta ? store.mostrarProyecto(entrega) : store.ocultarProyecto(entrega));
                  if (context.mounted) {
                    _mostrarResultado(context, error, entrega.oculta ? 'Proyecto regresado al tablero.' : 'Proyecto quitado del tablero.');
                  }
                },
                onEditar: () {},
                onEliminar: () {},
              )
            : _MenuAdmin(
                extras: [
                  PopupMenuItem(
                    value: 'entregada',
                    child: ListTile(
                      leading: Icon(entrega.entregada ? Icons.undo : Icons.check_circle_outline),
                      title: Text(entrega.entregada ? 'Marcar pendiente' : 'Marcar entregada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onExtra: (_) async {
                  final error = await TableroStore.instancia.marcarEntregada(entrega, !entrega.entregada);
                  if (context.mounted && error != null) _mostrarResultado(context, error, '');
                },
                onEditar: () => _editarEntrega(context, entrega),
                onEliminar: () async {
                  if (!await _confirmarEliminar(context, 'esta entrega')) return;
                  final error = await TableroStore.instancia.eliminarEntrega(entrega);
                  if (context.mounted) _mostrarResultado(context, error, 'Entrega eliminada.');
                },
              );

    return Opacity(
      opacity: entrega.oculta ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            // Día de entrega
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: esHoy ? AppTheme.primary : AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(_dias[entrega.fechaEntrega.weekday - 1],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: esHoy ? Colors.white70 : AppTheme.textSecondary)),
                  Text('${entrega.fechaEntrega.day}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: esHoy ? Colors.white : AppTheme.textPrimary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entrega.unidad,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: entrega.entregada ? AppTheme.textMuted : AppTheme.textPrimary,
                      decoration: entrega.entregada ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (detalle.isNotEmpty)
                    Text(detalle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: colorEstado.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(estado, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorEstado)),
            ),
            menuAdmin,
          ],
        ),
      ),
    );
  }
}

Future<void> _editarEntrega(BuildContext context, EntregaSemana? original) async {
  final nueva = original == null;
  final unidad = TextEditingController(text: original?.unidad ?? '');
  final cliente = TextEditingController(text: original?.cliente ?? '');
  final notas = TextEditingController(text: original?.notas ?? '');
  var fecha = original?.fechaEntrega ?? soloFecha(DateTime.now());
  var entregada = original?.entregada ?? false;
  final formKey = GlobalKey<FormState>();
  var guardando = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final fueraDeSemana = fecha.isBefore(TableroStore.inicioSemana) || fecha.isAfter(TableroStore.finSemana);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(nueva ? 'Programar entrega' : 'Editar entrega', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: unidad,
                      autofocus: true,
                      maxLength: 120,
                      decoration: _campo('Unidad', ayuda: 'Ej. Kenworth T680 #45, placas ABC-123'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'La unidad es obligatoria.' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(controller: cliente, maxLength: 150, decoration: _campo('Cliente (opcional)')),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final seleccion = await showDatePicker(
                          context: dialogContext,
                          initialDate: fecha,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (seleccion != null) setState(() => fecha = soloFecha(seleccion));
                      },
                      child: InputDecorator(
                        decoration: _campo(
                          'Fecha de entrega',
                          ayuda: fueraDeSemana ? 'Fuera de esta semana: aparecerá en el tablero esa semana.' : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text('${_dias[fecha.weekday - 1]} ${formatearFecha(fecha)}')),
                            const Icon(Icons.calendar_today_outlined, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: notas, maxLength: 1000, maxLines: 3, minLines: 1, decoration: _campo('Notas (opcional)')),
                    if (!nueva)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ya se entregó'),
                        value: entregada,
                        onChanged: (v) => setState(() => entregada = v),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: guardando ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => guardando = true);
                      final entrega = EntregaSemana(
                        id: original?.id ?? 0,
                        unidad: unidad.text.trim(),
                        cliente: cliente.text.trim().isEmpty ? null : cliente.text.trim(),
                        fechaEntrega: fecha,
                        notas: notas.text.trim().isEmpty ? null : notas.text.trim(),
                        entregada: entregada,
                        creadoPor: original?.creadoPor,
                      );
                      final error = await TableroStore.instancia.guardarEntrega(entrega, nueva: nueva);
                      if (!dialogContext.mounted) return;
                      if (error == null) {
                        Navigator.pop(dialogContext);
                        if (context.mounted) _mostrarResultado(context, null, nueva ? 'Entrega programada.' : 'Entrega actualizada.');
                      } else {
                        setState(() => guardando = false);
                        _mostrarResultado(dialogContext, error, '');
                      }
                    },
              child: Text(guardando ? 'Guardando…' : 'Guardar'),
            ),
          ],
        );
      },
    ),
  );
}

// =====================================================================
// 2. Coordinación operativa del día (post-its)
// =====================================================================

Color _colorPostIt(String color) => switch (color) {
      'rosa' => const Color(0xFFFBCFE8),
      'azul' => const Color(0xFFBFDBFE),
      'verde' => const Color(0xFFBBF7D0),
      'naranja' => const Color(0xFFFED7AA),
      _ => const Color(0xFFFEF08A),
    };

class _SeccionCoordinacion extends StatelessWidget {
  final List<NotaCoordinacion> notas;
  const _SeccionCoordinacion({required this.notas});

  @override
  Widget build(BuildContext context) {
    final corte = TableroStore.siguienteCorte;
    final cuando = soloFecha(corte) == soloFecha(DateTime.now()) ? 'hoy' : 'mañana';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EncabezadoSeccion(
          icono: Icons.groups_outlined,
          titulo: 'Coordinación operativa del día',
          subtitulo: 'Asignación de cuadrillas · se borra $cuando a las 7:00 pm',
          textoAgregar: 'Nota',
          onAgregar: () => _editarNota(context, null),
        ),
        CambioSuave(
          child: notas.isEmpty
              ? const _Vacio('Todavía no hay cuadrillas asignadas para hoy.')
              : LayoutBuilder(
            builder: (context, constraints) {
              // 2 post-its por fila en teléfono; más en pantallas anchas
              const espacio = 12.0;
              final porFila = (constraints.maxWidth / 200).floor().clamp(2, 6).toInt();
              final ancho = (constraints.maxWidth - espacio * (porFila - 1)) / porFila;
              return Wrap(
                spacing: espacio,
                runSpacing: espacio,
                // Con llave: una nota nueva entra con animación y las demás no se repiten
                children: [
                  for (final n in notas) SizedBox(key: ValueKey(n.id), width: ancho, child: Aparicion(child: _PostIt(nota: n))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PostIt extends StatelessWidget {
  final NotaCoordinacion nota;
  const _PostIt({required this.nota});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 14),
      decoration: BoxDecoration(
        color: _colorPostIt(nota.color),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(nota.cuadrilla, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              if (Sesion.esAdmin)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: _MenuAdmin(
                    color: Colors.black54,
                    onEditar: () => _editarNota(context, nota),
                    onEliminar: () async {
                      if (!await _confirmarEliminar(context, 'esta nota')) return;
                      final error = await TableroStore.instancia.eliminarNota(nota);
                      if (context.mounted) _mostrarResultado(context, error, 'Nota eliminada.');
                    },
                  ),
                )
              else
                const SizedBox(width: 10, height: 32),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(nota.asignacion, style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

Future<void> _editarNota(BuildContext context, NotaCoordinacion? original) async {
  final nueva = original == null;
  final cuadrilla = TextEditingController(text: original?.cuadrilla ?? '');
  final asignacion = TextEditingController(text: original?.asignacion ?? '');
  var color = original?.color ?? NotaCoordinacion.colores.first;
  final formKey = GlobalKey<FormState>();
  var guardando = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(nueva ? 'Nueva nota del día' : 'Editar nota', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: cuadrilla,
                    autofocus: true,
                    maxLength: 80,
                    decoration: _campo('Cuadrilla', ayuda: 'Ej. Cuadrilla 1, Pintura, Juan y Pedro'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La cuadrilla es obligatoria.' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: asignacion,
                    maxLength: 1000,
                    maxLines: 4,
                    minLines: 2,
                    decoration: _campo('Asignación', ayuda: '¿Qué le toca hoy a esta cuadrilla?'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La asignación es obligatoria.' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final c in NotaCoordinacion.colores)
                        GestureDetector(
                          onTap: () => setState(() => color = c),
                          child: Tooltip(
                            message: c,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _colorPostIt(c),
                                shape: BoxShape.circle,
                                border: Border.all(color: color == c ? Colors.black : Colors.black12, width: color == c ? 2.5 : 1),
                              ),
                              child: color == c ? const Icon(Icons.check, size: 18) : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Las notas se borran automáticamente todos los días a las 7:00 pm.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: guardando ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: guardando
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => guardando = true);
                    final nota = NotaCoordinacion(
                      id: original?.id ?? 0,
                      cuadrilla: cuadrilla.text.trim(),
                      asignacion: asignacion.text.trim(),
                      color: color,
                      creadoPor: original?.creadoPor,
                      creado: original?.creado ?? DateTime.now(),
                    );
                    final error = await TableroStore.instancia.guardarNota(nota, nueva: nueva);
                    if (!dialogContext.mounted) return;
                    if (error == null) {
                      Navigator.pop(dialogContext);
                      if (context.mounted) _mostrarResultado(context, null, nueva ? 'Nota agregada.' : 'Nota actualizada.');
                    } else {
                      setState(() => guardando = false);
                      _mostrarResultado(dialogContext, error, '');
                    }
                  },
            child: Text(guardando ? 'Guardando…' : 'Guardar'),
          ),
        ],
      ),
    ),
  );
}

// =====================================================================
// 3. Anuncios
// =====================================================================

class _SeccionAnuncios extends StatelessWidget {
  final List<Anuncio> anuncios;
  const _SeccionAnuncios({required this.anuncios});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EncabezadoSeccion(
          icono: Icons.campaign_outlined,
          titulo: 'Anuncios',
          subtitulo: anuncios.isEmpty ? 'Avisos generales para todo el taller' : '${anuncios.length} publicado${anuncios.length == 1 ? '' : 's'}',
          textoAgregar: 'Anuncio',
          onAgregar: () => _editarAnuncio(context, null),
        ),
        CambioSuave(
          child: anuncios.isEmpty
              ? const _Vacio('No hay anuncios.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final a in anuncios)
                      Aparicion(
                        key: ValueKey(a.id),
                        child: Padding(padding: const EdgeInsets.only(bottom: 10), child: _TarjetaAnuncio(anuncio: a)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TarjetaAnuncio extends StatelessWidget {
  final Anuncio anuncio;
  const _TarjetaAnuncio({required this.anuncio});

  @override
  Widget build(BuildContext context) {
    final pie = [
      if (anuncio.creadoPor != null && anuncio.creadoPor!.isNotEmpty) anuncio.creadoPor!,
      formatearFechaHora(anuncio.creado),
      if (anuncio.editado != null) 'editado',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.campaign_outlined, size: 20, color: AppTheme.textPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anuncio.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(anuncio.contenido, style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(pie, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          _MenuAdmin(
            onEditar: () => _editarAnuncio(context, anuncio),
            onEliminar: () async {
              if (!await _confirmarEliminar(context, 'este anuncio')) return;
              final error = await TableroStore.instancia.eliminarAnuncio(anuncio);
              if (context.mounted) _mostrarResultado(context, error, 'Anuncio eliminado.');
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _editarAnuncio(BuildContext context, Anuncio? original) async {
  final nuevo = original == null;
  final titulo = TextEditingController(text: original?.titulo ?? '');
  final contenido = TextEditingController(text: original?.contenido ?? '');
  final formKey = GlobalKey<FormState>();
  var guardando = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(nuevo ? 'Nuevo anuncio' : 'Editar anuncio', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titulo,
                    autofocus: true,
                    maxLength: 150,
                    decoration: _campo('Título'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es obligatorio.' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: contenido,
                    maxLength: 4000,
                    maxLines: 6,
                    minLines: 3,
                    decoration: _campo('Contenido'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El contenido es obligatorio.' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: guardando ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: guardando
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => guardando = true);
                    final anuncio = Anuncio(
                      id: original?.id ?? 0,
                      titulo: titulo.text.trim(),
                      contenido: contenido.text.trim(),
                      creadoPor: original?.creadoPor,
                      creado: original?.creado ?? DateTime.now(),
                      editado: original?.editado,
                    );
                    final error = await TableroStore.instancia.guardarAnuncio(anuncio, nuevo: nuevo);
                    if (!dialogContext.mounted) return;
                    if (error == null) {
                      Navigator.pop(dialogContext);
                      if (context.mounted) _mostrarResultado(context, null, nuevo ? 'Anuncio publicado.' : 'Anuncio actualizado.');
                    } else {
                      setState(() => guardando = false);
                      _mostrarResultado(dialogContext, error, '');
                    }
                  },
            child: Text(guardando ? 'Publicando…' : (nuevo ? 'Publicar' : 'Guardar')),
          ),
        ],
      ),
    ),
  );
}
