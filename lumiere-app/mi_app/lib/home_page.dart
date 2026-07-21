import 'package:flutter/material.dart';
import 'inventario.dart';
import 'reportes.dart';
import 'usuarios.dart';

// Paleta de colores
class _Colors {
  static const bg = Color(0xFFFAF8F5);
  static const card = Colors.white;
  static const border = Color(0xFFECE6DF);
  static const brand = Color(0xFF8C6239);
  static const brandLight = Color(0xFFE2B28B);
  static const textDark = Color(0xFF2D2D2D);
  static const textGray = Color(0xFF8E8E8E);
  static const success = Color(0xFF556B2F);

  // Sidebar
  static const sidebarBg = Color(0xFF332619);
  static const sidebarSelected = Color(0xFF4A3826);
  static const sidebarText = Color(0xFFF3E9DC);
  static const sidebarTextMuted = Color(0xFFB7A48D);
}

enum _NavSection { inventario, reportes, usuarios }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _NavSection _currentSection = _NavSection.inventario;

  Widget _buildCurrentPage() {
    switch (_currentSection) {
      case _NavSection.inventario:
        return const InventarioPage();
      case _NavSection.reportes:
        return const ReportesPage();
      case _NavSection.usuarios:
        return const UsuariosPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: Row(
        children: [
          // === SIDEBAR DE NAVEGACIÓN ===
          Container(
            width: 280,
            color: _Colors.sidebarBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo/Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: _Colors.brandLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'LUMIÈRE',
                            style: TextStyle(
                              color: _Colors.sidebarText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '& Co.',
                        style: TextStyle(
                          color: _Colors.sidebarTextMuted,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF4A3826), thickness: 1),
                // Items de Navegación
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      _NavTile(
                        icon: Icons.inventory_2_rounded,
                        label: 'Inventario',
                        isSelected: _currentSection == _NavSection.inventario,
                        onTap: () {
                          setState(() {
                            _currentSection = _NavSection.inventario;
                          });
                        },
                      ),
                      _NavTile(
                        icon: Icons.bar_chart_rounded,
                        label: 'Reportes',
                        isSelected: _currentSection == _NavSection.reportes,
                        onTap: () {
                          setState(() {
                            _currentSection = _NavSection.reportes;
                          });
                        },
                      ),
                      _NavTile(
                        icon: Icons.people_rounded,
                        label: 'Usuarios',
                        isSelected: _currentSection == _NavSection.usuarios,
                        onTap: () {
                          setState(() {
                            _currentSection = _NavSection.usuarios;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Footer info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _Colors.sidebarSelected,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Aplicación Web',
                          style: TextStyle(
                            color: _Colors.sidebarText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            color: _Colors.sidebarTextMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // === CONTENIDO PRINCIPAL ===
          Expanded(child: _buildCurrentPage()),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected ? _Colors.sidebarSelected : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? _Colors.brandLight : _Colors.sidebarTextMuted,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? _Colors.sidebarText : _Colors.sidebarTextMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        hoverColor: _Colors.sidebarSelected.withOpacity(0.5),
      ),
    );
  }
}
