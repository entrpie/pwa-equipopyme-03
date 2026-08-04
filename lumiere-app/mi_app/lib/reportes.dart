import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_app/ventas.dart' show tiempoRelativo;

// =================== PALETA DE COLORES (COHERENTE CON INVENTARIO) ===================
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      // Una sola suscripción a la colección `ventas` alimenta los KPIs, la
      // gráfica y el historial de esta pantalla con datos reales.
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ventas')
            .orderBy('fecha', descending: true)
            .limit(200)
            .snapshots(),
        builder: (context, snapshot) {
          final ventas = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera interna de Reportes
                _buildHeader(),
                const SizedBox(height: 24),

                // Fila de KPIs Principales
                _buildKpiCardsRow(ventas),
                const SizedBox(height: 24),

                // Contenedor principal: Gráfica de Ventas + Historial de Ventas
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 950) {
                      // Vista de Escritorio / Pantalla Ancha (Lado a Lado)
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildGraficaVentasCard(ventas),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildMovimientosCard(ventas),
                          ),
                        ],
                      );
                    } else {
                      // Vista Móvil (Uno debajo del otro)
                      return Column(
                        children: [
                          _buildGraficaVentasCard(ventas),
                          const SizedBox(height: 24),
                          _buildMovimientosCard(ventas),
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

  // Header con filtro temporal estético
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
                setState(() => _filtroTemporal = v!);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Tarjetas KPI (Ingresos, Ventas, Stock Crítico) calculadas a partir de la
  // colección `ventas` real (ver StreamBuilder en build()).
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
                ? 'Aún sin ventas'
                : '${ventas.length} venta(s) registradas',
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
            trend: 'Histórico registrado',
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

  // Gráfico de Ventas: agrega los totales reales de la colección `ventas`
  // por día para los últimos 7 días (hoy incluido).
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Ventas (\$)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ingresos reales de los últimos 7 días',
                    style: TextStyle(fontSize: 11, color: _Colors.textGray),
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

  // Historial de ventas reales, tomado de la misma colección `ventas` que
  // alimenta los KPIs y la gráfica de esta pantalla.
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
          const Text(
            'Últimas ventas registradas en el sistema',
            style: TextStyle(fontSize: 11, color: _Colors.textGray),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: recientes.isEmpty
                ? const Center(child: Text('Aún no hay ventas registradas.'))
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

// Componente para las tarjetas superiores KPI de Reportes
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
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
