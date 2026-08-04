import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== PALETA DE COLORES (COHERENTE CON INVENTARIO) ====================
class _Colors {
  static const bg = Color(0xFFFAF8F5);
  static const card = Colors.white;
  static const border = Color(0xFFECE6DF);
  static const brand = Color(0xFF8C6239);
  static const brandLight = Color(0xFFE2B28B);
  static const textDark = Color(0xFF2D2D2D);
  static const textGray = Color(0xFF8E8E8E);
  static const success = Color(0xFF556B2F);
  static const danger = Color(0xFFC97A7A);
}

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();

  String _searchQuery = '';
  bool _showAddPanel = false;
  bool _isSaving = false;
  bool _activo = true;
  String _rolSeleccionado = 'Administrador';

  final List<String> _roles = [
    'Administrador',
    'Supervisor',
    'Vendedor',
    'Operador',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filtrarUsuarios(
    List<QueryDocumentSnapshot> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final rol = (data['rol'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return query.isEmpty ||
          nombre.contains(query) ||
          email.contains(query) ||
          rol.contains(query);
    }).toList();
  }

  Future<void> _agregarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': _rolSeleccionado,
        'activo': _activo,
        'creadoEn': Timestamp.now(),
      });

      if (!mounted) return;

      _nombreController.clear();
      _emailController.clear();
      setState(() {
        _rolSeleccionado = 'Administrador';
        _activo = true;
        _showAddPanel = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Usuario agregado correctamente'),
          backgroundColor: _Colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo guardar el usuario'),
          backgroundColor: _Colors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildListaUsuarios(
    List<QueryDocumentSnapshot> docs,
    List<QueryDocumentSnapshot> filtrados,
  ) {
    final totalActivos = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['activo'] ?? false) == true;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.people_alt_rounded,
                label: 'Usuarios',
                value: '${docs.length}',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _KpiCard(
                icon: Icons.check_circle_rounded,
                label: 'Activos',
                value: '$totalActivos',
                accent: _Colors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Colors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuarios por nombre, email o rol',
                    hintStyle: TextStyle(
                      color: _Colors.textGray.withValues(alpha: 0.8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _Colors.textGray,
                    ),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAddPanel = !_showAddPanel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showAddPanel
                    ? _Colors.textDark
                    : _Colors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _showAddPanel
                    ? Icons.close_rounded
                    : Icons.person_add_alt_rounded,
                size: 18,
              ),
              label: Text(
                _showAddPanel ? 'Cerrar formulario' : 'Agregar Usuario',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: docs.isEmpty
              ? const Center(child: Text('AÃºn no hay usuarios registrados.'))
              : filtrados.isEmpty
              ? const Center(
                  child: Text('No hay usuarios que coincidan con la bÃºsqueda.'),
                )
              : ListView.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = filtrados[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = (data['nombre'] ?? 'Sin nombre').toString();
                    final email = (data['email'] ?? 'Sin email').toString();
                    final rol = (data['rol'] ?? 'Sin rol').toString();
                    final activo = (data['activo'] ?? false) == true;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: _Colors.brand.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: _Colors.brandLight,
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: _Colors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: _Colors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rol: $rol',
                                  style: const TextStyle(
                                    color: _Colors.brand,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: activo
                                  ? _Colors.success.withValues(alpha: 0.12)
                                  : _Colors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: activo
                                    ? _Colors.success
                                    : _Colors.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAddUserForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Usuario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _Colors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completa los datos para registrar un nuevo acceso.',
                style: TextStyle(fontSize: 12, color: _Colors.textGray),
              ),
              const SizedBox(height: 22),
              const Text(
                'Nombre completo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej. Sofia LÃ³pez',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _Colors.bg,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa un nombre vÃ¡lido'
                    : null,
              ),
              const SizedBox(height: 18),
              const Text(
                'Correo electrÃ³nico',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'usuario@lumiere.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _Colors.bg,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un correo';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  return emailRegex.hasMatch(value.trim())
                      ? null
                      : 'Correo invÃ¡lido';
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Rol',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _rolSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _Colors.bg,
                ),
                items: _roles.map((rol) {
                  return DropdownMenuItem<String>(value: rol, child: Text(rol));
                }).toList(),
                onChanged: (value) {
                  setState(() => _rolSeleccionado = value ?? 'Administrador');
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _Colors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado del usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _activo ? 'Activo y con acceso' : 'Inactivo',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _Colors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _activo,
                      onChanged: (value) => setState(() => _activo = value),
                      activeThumbColor: _Colors.brand,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _agregarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Colors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar usuario',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar usuarios.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _Colors.brand),
              );
            }

            final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];
            final filtrados = _filtrarUsuarios(docs);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildListaUsuarios(docs, filtrados)),
                if (_showAddPanel)
                  const VerticalDivider(width: 1, color: _Colors.border),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: _showAddPanel
                        ? SizedBox(width: 380, child: _buildAddUserForm())
                        : const SizedBox(width: 0),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
// ==================== WIDGETS DE SOPORTE COMPARTIDOS ====================

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (accent ?? _Colors.brand).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent ?? _Colors.brand, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Colors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accent ?? _Colors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
