import 'package:flutter/material.dart';
import '../models/catalogos.dart';
import '../services/catalogos_store.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/menu_lateral.dart';

/// Alta, edición y baja de usuarios del sistema (solo Admin).
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final CatalogosStore _store = CatalogosStore.instancia;
  String _busqueda = '';

  Future<void> _abrirFormulario([UsuarioSistema? usuario]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => _FormularioUsuario(usuario: usuario),
      );

  Future<void> _eliminar(UsuarioSistema usuario) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar usuario',
      message: '¿Eliminar a "${usuario.nombre}" (${usuario.username})? Ya no podrá iniciar sesión.',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );
    if (!confirmar) return;
    final error = await _store.eliminarUsuario(usuario);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Usuario eliminado.'), backgroundColor: error == null ? AppTheme.success : AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const MenuLateral(seccion: Seccion.usuarios),
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Nuevo usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ContenidoResponsivo(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final q = _busqueda.toLowerCase();
            final lista = _store.usuarios
                .where((u) => u.nombre.toLowerCase().contains(q) || u.username.toLowerCase().contains(q) || u.puesto.toLowerCase().contains(q))
                .toList();
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    decoration: AppTheme.inputDecoration('Buscar por nombre, usuario o puesto...', icon: Icons.search),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: lista.isEmpty
                        ? const Center(child: Text('No hay usuarios con ese criterio.', style: TextStyle(color: AppTheme.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: lista.length,
                            itemBuilder: (context, i) => _buildTarjeta(lista[i]),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTarjeta(UsuarioSistema u) {
    final esAdmin = u.rol == 'Admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: esAdmin ? AppTheme.primary : const Color(0xFFF1F2F4),
            child: Text(
              u.nombre.isEmpty ? '?' : u.nombre.trim()[0].toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: esAdmin ? Colors.white : AppTheme.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('@${u.username}${u.puesto.isEmpty ? '' : ' • ${u.puesto}'}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(rolesSistema[u.rol] ?? u.rol, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.info)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), tooltip: 'Editar', onPressed: () => _abrirFormulario(u)),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
            tooltip: 'Eliminar',
            onPressed: () => _eliminar(u),
          ),
        ],
      ),
    );
  }
}

class _FormularioUsuario extends StatefulWidget {
  final UsuarioSistema? usuario;

  const _FormularioUsuario({this.usuario});

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.usuario?.nombre ?? '');
  late final TextEditingController _username = TextEditingController(text: widget.usuario?.username ?? '');
  late final TextEditingController _puesto = TextEditingController(text: widget.usuario?.puesto ?? '');
  late final TextEditingController _contacto = TextEditingController(text: widget.usuario?.contacto ?? '');
  final TextEditingController _password = TextEditingController();
  late String _rol = rolesSistema.containsKey(widget.usuario?.rol) ? widget.usuario!.rol : 'Usuario';
  bool _ocultar = true;
  bool _guardando = false;
  String? _error;

  bool get _editando => widget.usuario != null;

  @override
  void dispose() {
    for (final c in [_nombre, _username, _puesto, _contacto, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await CatalogosStore.instancia.guardarUsuario(
      existente: widget.usuario,
      nombre: _nombre.text,
      username: _username.text,
      rol: _rol,
      puesto: _puesto.text,
      contacto: _contacto.text,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error != null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(_editando ? 'Usuario actualizado.' : 'Usuario registrado.'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_editando ? 'Editar usuario' : 'Nuevo usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              _etiqueta('Nombre completo *'),
              TextFormField(
                controller: _nombre,
                validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa al menos 3 caracteres' : null,
                decoration: AppTheme.inputDecoration('Ej. Sergio Urey Morales', icon: Icons.badge_outlined),
              ),
              _etiqueta('Usuario para iniciar sesión *'),
              TextFormField(
                controller: _username,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el usuario' : null,
                decoration: AppTheme.inputDecoration('Ej. surey', icon: Icons.alternate_email),
              ),
              _etiqueta(_editando ? 'Nueva contraseña (déjala vacía para no cambiarla)' : 'Contraseña *'),
              TextFormField(
                controller: _password,
                obscureText: _ocultar,
                validator: (v) {
                  final texto = v ?? '';
                  if (!_editando && texto.length < 8) return 'Mínimo 8 caracteres';
                  if (_editando && texto.isNotEmpty && texto.length < 8) return 'Mínimo 8 caracteres';
                  return null;
                },
                decoration: AppTheme.inputDecoration(
                  'Mínimo 8 caracteres',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(_ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  ),
                ),
              ),
              _etiqueta('Rol *'),
              DropdownButtonFormField<String>(
                initialValue: _rol,
                isExpanded: true,
                decoration: AppTheme.inputDecoration('Rol', icon: Icons.admin_panel_settings_outlined),
                items: [
                  for (final r in rolesSistema.entries) DropdownMenuItem(value: r.key, child: Text(r.value, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _rol = v);
                },
              ),
              _etiqueta('Puesto / área'),
              TextFormField(controller: _puesto, decoration: AppTheme.inputDecoration('Ej. Almacén', icon: Icons.work_outline)),
              _etiqueta('Contacto'),
              TextFormField(controller: _contacto, decoration: AppTheme.inputDecoration('Teléfono o correo', icon: Icons.phone_outlined)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_editando ? 'Guardar cambios' : 'Registrar usuario',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
