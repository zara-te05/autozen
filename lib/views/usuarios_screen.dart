import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/status_badge.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Catálogo de departamentos autorizados en el sistema
  static const List<String> _departamentosValidos = [
    'Almacén General',
    'Soldadura y Chasis',
    'Pintura y Estética',
    'Mecánica Diésel',
    'Administración General',
  ];

  // Base de datos local simulada de usuarios
  final List<Map<String, dynamic>> _usuarios = [
    {
      'id': 'USR-001',
      'nombre': 'Ing. Carlos Mendoza',
      'email': 'admin@autosen.com',
      'rol': 'admin',
      'departamento': 'Administración General',
      'activo': true,
    },
    {
      'id': 'USR-002',
      'nombre': 'Gabriela Gómez',
      'email': 'gabriela@autosen.com',
      'rol': 'encargado',
      'departamento': 'Almacén General',
      'activo': true,
    },
    {
      'id': 'USR-003',
      'nombre': 'Sergio Urey Morales',
      'email': 'sergio@autosen.com',
      'rol': 'encargado',
      'departamento': 'Soldadura y Chasis',
      'activo': true,
    },
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _rolSeleccionado = 'encargado';
  String _departamentoSeleccionado = 'Mecánica Diésel';
  String _searchQuery = '';
  Map<String, dynamic>? _usuarioEnEdicion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _generarNuevoId() {
    return 'USR-${(_usuarios.length + 1).toString().padLeft(3, '0')}';
  }

  void _guardarUsuario() {
    if (!_formKey.currentState!.validate()) return;

    final String nombre = _nombreController.text.trim();
    final String email = _emailController.text.trim();

    setState(() {
      if (_usuarioEnEdicion != null) {
        _usuarioEnEdicion!['nombre'] = nombre;
        _usuarioEnEdicion!['email'] = email;
        _usuarioEnEdicion!['rol'] = _rolSeleccionado;
        _usuarioEnEdicion!['departamento'] = _departamentoSeleccionado;
        _usuarioEnEdicion = null;
      } else {
        _usuarios.insert(0, {
          'id': _generarNuevoId(),
          'nombre': nombre,
          'email': email,
          'rol': _rolSeleccionado,
          'departamento': _departamentoSeleccionado,
          'activo': true,
        });
      }

      _nombreController.clear();
      _emailController.clear();
      _rolSeleccionado = 'encargado';
      _departamentoSeleccionado = 'Mecánica Diésel';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usuario "$nombre" guardado exitosamente.'),
        backgroundColor: Colors.black87,
      ),
    );

    _tabController.animateTo(0);
  }

  void _iniciarEdicion(Map<String, dynamic> usuario) {
    setState(() {
      _usuarioEnEdicion = usuario;
      _nombreController.text = usuario['nombre'];
      _emailController.text = usuario['email'];
      _rolSeleccionado = usuario['rol'];
      _departamentoSeleccionado = usuario['departamento'];
    });
    _tabController.animateTo(1);
  }

  Future<void> _eliminarUsuario(Map<String, dynamic> usuario) async {
    final bool confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar Usuario',
      message: '¿Estás seguro de que deseas revocar y eliminar a "${usuario['nombre']}" (${usuario['id']})? Esta acción no se puede deshacer.',
      confirmText: 'Sí, Eliminar',
      isDestructive: true,
      icon: Icons.person_remove_rounded,
    );

    if (confirmar) {
      setState(() {
        _usuarios.removeWhere((u) => u['id'] == usuario['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario ${usuario['nombre']} eliminado del sistema.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            const Tab(text: 'Lista de Usuarios'),
            Tab(text: _usuarioEnEdicion == null ? 'Nuevo Usuario' : 'Editar Usuario'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaUsuarios(),
          _buildFormularioDefensivo(),
        ],
      ),
    );
  }

  // ================================================================
  // PESTAÑA 1: LISTADO DEFENSIVO (Sin pedir IDs a ciegas al usuario)
  // ================================================================
  Widget _buildListaUsuarios() {
    final filtrados = _usuarios.where((u) {
      final q = _searchQuery.toLowerCase();
      return u['nombre'].toString().toLowerCase().contains(q) ||
          u['id'].toString().toLowerCase().contains(q) ||
          u['departamento'].toString().toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Buscador controlado con botón de limpiar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: AppTheme.inputDecoration(
              'Buscar por nombre, ID o departamento...',
              icon: Icons.search,
              suffix: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: filtrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No se encontraron usuarios registrados.', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final u = filtrados[index];
                      final bool esAdmin = u['rol'] == 'admin';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: esAdmin ? Colors.black : const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                esAdmin ? Icons.admin_panel_settings : Icons.person,
                                color: esAdmin ? Colors.white : AppTheme.info,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(u['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                        label: esAdmin ? 'ADMIN' : 'ENCARGADO',
                                        type: esAdmin ? BadgeType.neutral : BadgeType.info,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${u['id']} • ${u['departamento']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  Text(u['email'], style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            // Botones de acción protegidos
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                              tooltip: 'Editar datos',
                              onPressed: () => _iniciarEdicion(u),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                              tooltip: 'Eliminar usuario',
                              onPressed: () => _eliminarUsuario(u),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PESTAÑA 2: FORMULARIO DEFENSIVO (Campos cerrados y validados)
  // ================================================================
  Widget _buildFormularioDefensivo() {
    final String idMostrar = _usuarioEnEdicion != null ? _usuarioEnEdicion!['id'] : _generarNuevoId();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _usuarioEnEdicion == null ? 'Nuevo Empleado' : 'Modificar Empleado',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('ID: $idMostrar (Auto)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),

              // Nombre completo
              const Text('Nombre completo *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'El nombre es obligatorio';
                  if (val.trim().length < 3) return 'Ingresa al menos 3 caracteres';
                  return null;
                },
                decoration: AppTheme.inputDecoration('Ej. Sergio Urey Morales', icon: Icons.badge_outlined),
              ),
              const SizedBox(height: 18),

              // Correo electrónico
              const Text('Correo corporativo *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'El correo es obligatorio';
                  if (!val.contains('@') || !val.contains('.')) return 'Ingresa un formato de correo válido';
                  return null;
                },
                decoration: AppTheme.inputDecoration('ejemplo@autosen.com', icon: Icons.alternate_email),
              ),
              const SizedBox(height: 18),

              // Rol de usuario (Cerrado a opciones del sistema)
              const Text('Rol de acceso al sistema *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _rolSeleccionado,
                decoration: AppTheme.inputDecoration('Rol'),
                items: const [
                  DropdownMenuItem(value: 'encargado', child: Text('Encargado de Área (Operativo)')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador (Acceso total)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _rolSeleccionado = val);
                },
              ),
              const SizedBox(height: 18),

              // Departamento asignado (Cerrado a lista oficial, sin texto libre)
              const Text('Área / Departamento asignado *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _departamentoSeleccionado,
                decoration: AppTheme.inputDecoration('Departamento'),
                items: _departamentosValidos.map((dep) {
                  return DropdownMenuItem(value: dep, child: Text(dep));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _departamentoSeleccionado = val);
                },
              ),
              const SizedBox(height: 32),

              // Botones de acción
              Row(
                children: [
                  if (_usuarioEnEdicion != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _usuarioEnEdicion = null;
                            _nombreController.clear();
                            _emailController.clear();
                          });
                          _tabController.animateTo(0);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_usuarioEnEdicion != null) const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _guardarUsuario,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        _usuarioEnEdicion == null ? 'Registrar Usuario' : 'Guardar Cambios',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}