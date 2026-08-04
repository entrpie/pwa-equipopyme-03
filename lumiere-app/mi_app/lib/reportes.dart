import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_app/ventas.dart' show tiempoRelativo;

// =================== PALETA DE COLORES ===================
class _Colors {
  static const bg = Color(0xFFFAF8F5);
  static const border = Color(0xFFECE6DF);
  static const brand = Color(0xFF8C6239);
  static const brandLight = Color(0xFFE2B28B);
  static const textDark = Color(0xFF2D2D2D);
  static const textGray = Color(0xFF8E8E8E);
  static const success = Color(0xFF556B2F);
  static const danger = Color(0xFFC97A7A);
}

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  String _filtroTemporal = 'Este Mes';

  // Función para filtrar los documentos según la fecha seleccionada
  List<QueryDocumentSnapshot> _filtrarVentasPorPeriodo(
      List<QueryDocumentSnapshot> todasLasVentas) {
    final ahora = DateTime.now();

    return todasLasVentas.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['fecha'];
      if (ts is! Timestamp) return false;

      final fechaVenta = ts.toDate();

      switch (_filtroTemporal) {
        case 'Esta Semana':
          // Calcula el inicio de la semana actual (Lunes)
          final inicioSemana = DateTime(ahora.year, ahora.month, ahora.day)
              .subtract(Duration(days: ahora.weekday - 1));
          return fechaVenta.isAfter(inicioSemana) ||
              fechaVenta.isAtSameMomentAs(inicioSemana);

        case 'Este Mes':
          // Mismo mes y año
          return fechaVenta.year == ahora.year &&
              fechaVenta.month == ahora.month;

        case 'Este Año':
          // Mismo año
          return fechaVenta.year == ahora.year;

        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ventas')
            .orderBy('fecha', descending: true)
            .limit(300)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _Colors.brand),
            );
          }

          final todasLasVentas = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];
          final ventasFiltradas = _filtrarVentasPorPeriodo(todasLasVentas);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera interna
                _buildHeader(),
                const SizedBox(height: 24),

                // Fila de KPIs Principales
                _buildKpiCardsRow(ventasFiltradas),
                const SizedBox(height: 24),

                // Contenedor principal: Gráfica + Historial
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 950) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildGraficaVentasCard(ventasFiltradas),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildMovimientosCard(ventasFiltradas),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildGraficaVentasCard(ventasFiltradas),
                          const SizedBox(height: 24),
                          _buildMovimientosCard(ventasFiltradas),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Header con selector de filtro funcional
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rendimiento del Negocio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _Colors.textDark,
              ),
            ),
            Text(
              'Visualiza ingresos, tendencias y rotación de producto.',
              style: TextStyle(fontSize: 12, color: _Colors.textGray),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filtroTemporal,
              items: <String>['Esta Semana', 'Este Mes', 'Este Año'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _Colors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _filtroTemporal = v);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Tarjetas KPI calculadas con las ventas filtradas
  Widget _buildKpiCardsRow(List<QueryDocumentSnapshot> ventas) {
    final totalIngresos = ventas.fold<double>(
      0,
      (suma, doc) =>
          suma + ((doc.data() as Map<String, dynamic>)['total'] ?? 0).toDouble(),
    );

    return Row(
      children: [
        Expanded(
          child: _KpiReportCard(
            title: 'Ingresos Totales',
            value: '\$${totalIngresos.toStringAsFixed(2)}',
            trend: ventas.isEmpty
                ? 'Sin ventas en este periodo'
                : '${ventas.length} venta(s) en $_filtroTemporal',
            trendIsPositive: true,
            icon: Icons.payments_outlined,
            accentColor: _Colors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiReportCard(
            title: 'Pedidos Completados',
            value: '${ventas.length}',
            trend: 'Filtrado por: $_filtroTemporal',
            trendIsPositive: true,
            icon: Icons.shopping_bag_outlined,
            accentColor: _Colors.brand,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('productos')
                .snapshots(),
            builder: (context, snapshot) {
              int stockBajoCount = 0;
              if (snapshot.hasData) {
                stockBajoCount = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['stock'] ?? 0) < 5;
                }).length;
              }
              return _KpiReportCard(
                title: 'Alertas de Stock',
                value: '$stockBajoCount',
                trend: stockBajoCount > 0 ? 'Requiere atención' : 'Todo al día',
                trendIsPositive: stockBajoCount == 0,
                icon: Icons.warning_amber_rounded,
                accentColor: stockBajoCount > 0
                    ? _Colors.danger
                    : _Colors.success,
              );
            },
          ),
        ),
      ],
    );
  }

  // Gráfica de Ventas
  Widget _buildGraficaVentasCard(List<QueryDocumentSnapshot> ventas) {
    final hoy = DateTime.now();
    final dias = List.generate(
      7,
      (i) => DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
      ).subtract(Duration(days: 6 - i)),
    );
    final totalesPorDia = List<double>.filled(7, 0);

    for (final doc in ventas) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['fecha'];
      if (ts is! Timestamp) continue;
      final fecha = ts.toDate();
      final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
      final idx = dias.indexWhere((d) => d == fechaSolo);
      if (idx != -1) {
        totalesPorDia[idx] += (data['total'] ?? 0).toDouble();
      }
    }

    final maxTotal = totalesPorDia.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );
    final maxY = maxTotal <= 0 ? 100.0 : maxTotal * 1.2;
    const nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Container(
      height: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historial de Ventas (\$)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ingresos registrados ($_filtroTemporal)',
                    style: const TextStyle(fontSize: 11, color: _Colors.textGray),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: _Colors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: _Colors.textGray,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        );
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dias.length) {
                          return const Text('');
                        }
                        return Text(
                          nombresDias[dias[idx].weekday - 1],
                          style: style,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            color: _Colors.textGray,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      7,
                      (i) => FlSpot(i.toDouble(), totalesPorDia[i]),
                    ),
                    isCurved: true,
                    color: _Colors.brand,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _Colors.brandLight.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lista de Movimientos/Ventas filtrada
  Widget _buildMovimientosCard(List<QueryDocumentSnapshot> ventas) {
    final recientes = ventas.take(10).toList();

    return Container(
      height: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas Recientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mostrando ventas de: $_filtroTemporal',
            style: const TextStyle(fontSize: 11, color: _Colors.textGray),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: recientes.isEmpty
                ? const Center(
                    child: Text(
                      'Sin ventas en el periodo seleccionado.',
                      style: TextStyle(color: _Colors.textGray, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: recientes.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: _Colors.border, height: 16),
                    itemBuilder: (context, index) {
                      final data =
                          recientes[index].data() as Map<String, dynamic>;
                      final nombre = (data['productoNombre'] ?? 'Producto')
                          .toString();
                      final cantidad = (data['cantidad'] ?? 0) as int;
                      final total = ((data['total'] ?? 0) as num).toDouble();
                      final ts = data['fecha'];
                      final fechaTexto = ts is Timestamp
                          ? tiempoRelativo(ts.toDate())
                          : '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _Colors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: _Colors.success,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _Colors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          '$fechaTexto · x$cantidad',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _Colors.textGray,
                          ),
                        ),
                        trailing: Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _Colors.success,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Componente Tarjeta KPI
class _KpiReportCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendIsPositive;
  final IconData icon;
  final Color accentColor;

  const _KpiReportCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendIsPositive,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: _Colors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: _Colors.brand, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                trendIsPositive ? Icons.north_rounded : Icons.south_rounded,
                size: 12,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}