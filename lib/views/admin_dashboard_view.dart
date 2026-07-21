import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../theme/theme.dart';
import '../services/database_service.dart';
import 'dart:async';

class AdminDashboardView extends StatefulWidget {
  final RestaurantController controller;

  const AdminDashboardView({super.key, required this.controller});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
        backgroundColor: AppTheme.surfaceLight,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Row(
        children: [
          // Navigation Rail (Microsoft Teams benzeri sol menü)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: AppTheme.surfaceLight,
            selectedIconTheme: const IconThemeData(color: AppTheme.primary),
            unselectedIconTheme: IconThemeData(color: AppTheme.textMuted.withOpacity(0.5)),
            selectedLabelTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.8)),
            
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Genel Durum'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: Text('Günlük Özet'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: Text('Tüm Satışlar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Günlük Satış Verileri'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Haftalık Satış Verileri'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bug_report_outlined),
                selectedIcon: Icon(Icons.bug_report),
                label: Text('Test Verisi'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Ana İçerik Alanı
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _GeneralStatsPage(controller: widget.controller);
      case 1:
        return const _DailySummaryPage();
      case 2:
        return const _AllSalesPage();
      case 3:
        return const _AnalyticsLogPage();
      case 4:
        return const _WeeklySalesDataPage(); 
      case 5:
        return _MockDataPage(controller: widget.controller);
      default:
        return const Center(child: Text('Sayfa bulunamadı'));
    }
  }
}

// --------------------------------------------------------------------
// GENEL DURUM SAYFASI
// --------------------------------------------------------------------
class _GeneralStatsPage extends StatelessWidget {
  final RestaurantController controller;

  const _GeneralStatsPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final activeTables = controller.tables.where((t) => t.status != TableStatus.empty).toList();
        final activeOrderAmount = activeTables.fold(0.0, (sum, t) => sum + t.currentTotal);
        final emptyTablesCount = controller.tables.length - activeTables.length;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anlık Restoran Durumu',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aşağıdaki veriler şu an restoranda oturan aktif masaları göstermektedir.',
                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _buildStatCard('Aktif Masa', activeTables.length.toString(), Icons.table_restaurant, AppTheme.pastelBlue),
                    const SizedBox(width: 24),
                    _buildStatCard('Boş Masa', emptyTablesCount.toString(), Icons.event_seat, AppTheme.pastelGreen),
                    const SizedBox(width: 24),
                    _buildStatCard('Açık Sipariş Toplamı', '${activeOrderAmount.toStringAsFixed(2)} ₺', Icons.receipt_long, AppTheme.pastelYellow),
                  ],
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  height: 600,
                  child: _LiveHourlyComparisonGraph(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------
// CANLI SAATLİK CİRO KARŞILAŞTIRMA GRAFİĞİ
// --------------------------------------------------------------------
class _LiveHourlyComparisonGraph extends StatefulWidget {
  const _LiveHourlyComparisonGraph();

  @override
  State<_LiveHourlyComparisonGraph> createState() =>
      _LiveHourlyComparisonGraphState();
}

class _LiveHourlyComparisonGraphState
    extends State<_LiveHourlyComparisonGraph> {
  Timer? _timer;

  bool isLoading = true;
  List<double> todayHourly = List<double>.filled(24, 0);
  List<double> yesterdayHourly = List<double>.filled(24, 0);
  DateTime lastUpdated = DateTime.now();

  int? hoveredCompletedHour;

  @override
  void initState() {
    super.initState();
    _loadGraphData();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadGraphData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGraphData() async {
    final now = DateTime.now();

    final todayData =
        await DatabaseService.instance.getHourlyBusinessRevenueForDate(now);

    final yesterdayData =
        await DatabaseService.instance.getHourlyBusinessRevenueForDate(
      now.subtract(const Duration(days: 1)),
    );

    if (!mounted) return;

    setState(() {
      todayHourly = todayData;
      yesterdayHourly = yesterdayData;
      lastUpdated = now;
      isLoading = false;
    });
  }

  double _sumUntilHour(List<double> values, int exclusiveHour) {
    if (exclusiveHour <= 0) return 0;

    final safeHour = exclusiveHour.clamp(0, 24);

    double total = 0;
    for (int i = 0; i < safeHour; i++) {
      total += values[i];
    }

    return total;
  }

  double _percentageDifference(double today, double yesterday) {
    if (yesterday == 0) {
      if (today == 0) return 0;
      return 100;
    }

    return ((today / yesterday) - 1) * 100;
  }

  int? _hoveredHourFromPosition({
  required Offset localPosition,
  required Size size,
}) {
  final completedHour = lastUpdated.hour;

  if (completedHour <= 0) {
    return null;
  }

  const double leftPadding = 72;
  const double rightPadding = 24;
  const double topPadding = 16;
  const double bottomPadding = 46;

  final chartLeft = leftPadding;
  final chartRight = size.width - rightPadding;
  final chartTop = topPadding;
  final chartBottom = size.height - bottomPadding;
  final chartWidth = chartRight - chartLeft;

  if (localPosition.dx < chartLeft ||
      localPosition.dx > chartRight ||
      localPosition.dy < chartTop ||
      localPosition.dy > chartBottom) {
    return null;
  }

  final relativeX = localPosition.dx - chartLeft;
  final rawHour = ((relativeX / chartWidth) * 24).round();

  return rawHour.clamp(1, completedHour).toInt();
}

_HourlyHoverInfo _buildHoverInfo(int completedHour) {
  final todayValue = _sumUntilHour(todayHourly, completedHour);
  final yesterdayValue = _sumUntilHour(yesterdayHourly, completedHour);
  final differenceAmount = todayValue - yesterdayValue;
  final percentage = _percentageDifference(todayValue, yesterdayValue);

  return _HourlyHoverInfo(
    completedHour: completedHour,
    todayValue: todayValue,
    yesterdayValue: yesterdayValue,
    differenceAmount: differenceAmount,
    percentage: percentage,
  );
}

Offset _tooltipOffsetForHour({
  required int completedHour,
  required Size size,
}) {
  const double leftPadding = 72;
  const double rightPadding = 24;

  final chartLeft = leftPadding;
  final chartRight = size.width - rightPadding;
  final chartWidth = chartRight - chartLeft;

  final x = chartLeft + (completedHour / 24.0) * chartWidth;

  final tooltipX = x > size.width - 260 ? size.width - 270 : x + 12;

  return Offset(
    tooltipX.clamp(12.0, size.width - 270),
    18,
  );
}

  List<_HourlyGraphPoint> _buildYesterdayPoints() {
    final points = <_HourlyGraphPoint>[];
    double cumulative = 0;

    points.add(const _HourlyGraphPoint(hour: 0, revenue: 0));

    for (int hour = 0; hour < 24; hour++) {
      cumulative += yesterdayHourly[hour];
      points.add(
        _HourlyGraphPoint(
          hour: hour + 1.0,
          revenue: cumulative,
        ),
      );
    }

    return points;
  }

  List<_HourlyGraphPoint> _buildTodayPoints() {
    final points = <_HourlyGraphPoint>[];
    final now = lastUpdated;

    double cumulative = 0;
    points.add(const _HourlyGraphPoint(hour: 0, revenue: 0));

    for (int hour = 0; hour < now.hour; hour++) {
      cumulative += todayHourly[hour];
      points.add(
        _HourlyGraphPoint(
          hour: hour + 1.0,
          revenue: cumulative,
        ),
      );
    }

    final currentHourProgress =
        now.hour + (now.minute / 60) + (now.second / 3600);

    cumulative += todayHourly[now.hour];

    points.add(
      _HourlyGraphPoint(
        hour: currentHourProgress,
        revenue: cumulative,
      ),
    );

    return points;
  }

  @override
Widget build(BuildContext context) {
  if (isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.12),
        ),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  final completedHour = lastUpdated.hour;

  final todayCompleted = _sumUntilHour(todayHourly, completedHour);
  final yesterdayCompleted = _sumUntilHour(yesterdayHourly, completedHour);
  final completedDifference =
      _percentageDifference(todayCompleted, yesterdayCompleted);

  final todayCurrentHour = todayHourly[lastUpdated.hour];
  final yesterdayCurrentHour = yesterdayHourly[lastUpdated.hour];
  final currentHourDifference =
      _percentageDifference(todayCurrentHour, yesterdayCurrentHour);

  final todayPoints = _buildTodayPoints();
  final yesterdayPoints = _buildYesterdayPoints();

  final double todayTotal =
      todayPoints.isEmpty ? 0.0 : todayPoints.last.revenue;

  final double yesterdaySamePoint =
      yesterdayCompleted + yesterdayCurrentHour;

  final overallDifference =
      _percentageDifference(todayTotal, yesterdaySamePoint);

  final double maxRevenue = dart_math.max(
    100.0,
    dart_math.max(
      todayPoints.fold<double>(
        0.0,
        (max, p) => dart_math.max(max, p.revenue),
      ),
      yesterdayPoints.fold<double>(
        0.0,
        (max, p) => dart_math.max(max, p.revenue),
      ),
    ),
  );

  const Color todayColor = Color(0xFFFF9F1C);
  const Color yesterdayColor = Color(0xFFB0B7C3);

  final bool isPositive = overallDifference >= 0;
  final Color diffColor = isPositive ? Colors.green : Colors.red;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppTheme.textMuted.withOpacity(0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.textMuted.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GÜNLÜK SATIŞIM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatMoneyLarge(todayTotal),
                          style: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            height: 1.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 18,
                              color: diffColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '%${overallDifference.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: diffColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textMuted.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      'Dünkü aynı saat toplamı: ${_formatMoneyLarge(yesterdaySamePoint)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Son Güncelleme: ${_formatFullDateTime(lastUpdated)}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GraphLegendDot(color: todayColor, label: 'Bugün'),
                    const SizedBox(width: 18),
                    _GraphLegendDot(color: yesterdayColor, label: 'Dün'),
                  ],
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 22),

        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MiniGraphInfoCard(
                    title: 'Tamamlanan Saatler',
                    value:
                        '${_formatMoneyLarge(todayCompleted)} / Dün: ${_formatMoneyLarge(yesterdayCompleted)}',
                    percentage: completedDifference,
                  ),
                  const SizedBox(height: 14),
                  _MiniGraphInfoCard(
                    title: 'Bu Saat',
                    value:
                        '${_formatMoneyLarge(todayCurrentHour)} / Dün: ${_formatMoneyLarge(yesterdayCurrentHour)}',
                    percentage: currentHourDifference,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _MiniGraphInfoCard(
                    title: 'Tamamlanan Saatler',
                    value:
                        '${_formatMoneyLarge(todayCompleted)} / Dün: ${_formatMoneyLarge(yesterdayCompleted)}',
                    percentage: completedDifference,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MiniGraphInfoCard(
                    title: 'Bu Saat',
                    value:
                        '${_formatMoneyLarge(todayCurrentHour)} / Dün: ${_formatMoneyLarge(yesterdayCurrentHour)}',
                    percentage: currentHourDifference,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        Expanded(
  child: Container(
    padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.45),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppTheme.textMuted.withOpacity(0.08),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        final hoverInfo = hoveredCompletedHour == null
            ? null
            : _buildHoverInfo(hoveredCompletedHour!);

        final tooltipOffset = hoveredCompletedHour == null
            ? null
            : _tooltipOffsetForHour(
                completedHour: hoveredCompletedHour!,
                size: chartSize,
              );

        return MouseRegion(
          onHover: (event) {
            final hour = _hoveredHourFromPosition(
              localPosition: event.localPosition,
              size: chartSize,
            );

            if (hour != hoveredCompletedHour) {
              setState(() {
                hoveredCompletedHour = hour;
              });
            }
          },
          onExit: (_) {
            setState(() {
              hoveredCompletedHour = null;
            });
          },
          child: Stack(
            children: [
              CustomPaint(
                painter: _HourlyRevenueChartPainter(
                  todayPoints: todayPoints,
                  yesterdayPoints: yesterdayPoints,
                  maxRevenue: maxRevenue * 1.10,
                  todayColor: todayColor,
                  yesterdayColor: yesterdayColor,
                  hoveredCompletedHour: hoveredCompletedHour,
                ),
                child: const SizedBox.expand(),
              ),

              if (hoverInfo != null && tooltipOffset != null)
                Positioned(
                  left: tooltipOffset.dx,
                  top: tooltipOffset.dy,
                  child: _HourlyHoverTooltip(info: hoverInfo),
                ),
            ],
          ),
        );
      },
    ),
  ),
),
      ],
    ),
  );
}
}

class _ComparisonInfoBox extends StatelessWidget {
  final String title;
  final String description;
  final double todayValue;
  final double yesterdayValue;
  final double percentage;

  const _ComparisonInfoBox({
    required this.title,
    required this.description,
    required this.todayValue,
    required this.yesterdayValue,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentage >= 0;
    final percentageColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatMoneyCompact(todayValue),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dün: ${_formatMoneyCompact(yesterdayValue)}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: percentageColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool thick;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.thick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: thick ? 5 : 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HourlyGraphPoint {
  final double hour;
  final double revenue;

  const _HourlyGraphPoint({
    required this.hour,
    required this.revenue,
  });
}

class _HourlyRevenueChartPainter extends CustomPainter {
  final List<_HourlyGraphPoint> todayPoints;
  final List<_HourlyGraphPoint> yesterdayPoints;
  final double maxRevenue;
  final Color todayColor;
  final Color yesterdayColor;
  final int? hoveredCompletedHour;

  const _HourlyRevenueChartPainter({
  required this.todayPoints,
  required this.yesterdayPoints,
  required this.maxRevenue,
  required this.todayColor,
  required this.yesterdayColor,
  required this.hoveredCompletedHour,
});

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 72;
    const double rightPadding = 24;
    const double topPadding = 16;
    const double bottomPadding = 46;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      size.width - leftPadding - rightPadding,
      size.height - topPadding - bottomPadding,
    );

    final axisPaint = Paint()
      ..color = AppTheme.textMuted.withOpacity(0.35)
      ..strokeWidth = 1.2;

    final gridPaint = Paint()
      ..color = AppTheme.textMuted.withOpacity(0.12)
      ..strokeWidth = 1;

    // background grid horizontal
    for (int i = 0; i <= 4; i++) {
      final y = chartRect.bottom - (chartRect.height / 4) * i;
      final value = (maxRevenue / 4) * i;

      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );

      _drawText(
        canvas,
        _formatMoneyCompact(value),
        Offset(8, y - 8),
        AppTheme.textMuted,
        12,
      );
    }

    // background grid vertical
    for (int hour = 0; hour <= 24; hour += 2) {
      final x = chartRect.left + (hour / 24.0) * chartRect.width;

      canvas.drawLine(
        Offset(x, chartRect.top),
        Offset(x, chartRect.bottom),
        gridPaint,
      );

      _drawText(
        canvas,
        hour.toString().padLeft(2, '0'),
        Offset(x - 10, chartRect.bottom + 10),
        AppTheme.textMuted,
        12,
      );
    }

    // axes
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );

    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      axisPaint,
    );

    _drawFilledAreaUnderLine(
      canvas: canvas,
      points: todayPoints,
      chartRect: chartRect,
      color: todayColor.withOpacity(0.10),
    );

    _drawLine(
      canvas: canvas,
      points: yesterdayPoints,
      chartRect: chartRect,
      color: yesterdayColor,
      strokeWidth: 3,
    );

    _drawLine(
      canvas: canvas,
      points: todayPoints,
      chartRect: chartRect,
      color: todayColor,
      strokeWidth: 4,
    );

    _drawMarkers(
      canvas: canvas,
      points: yesterdayPoints,
      chartRect: chartRect,
      color: yesterdayColor,
      radius: 3.2,
    );

    _drawMarkers(
      canvas: canvas,
      points: todayPoints,
      chartRect: chartRect,
      color: todayColor,
      radius: 4.0,
    );

    _drawHoverGuide(
      canvas: canvas,
      chartRect: chartRect,
    );
  }

  void _drawFilledAreaUnderLine({
    required Canvas canvas,
    required List<_HourlyGraphPoint> points,
    required Rect chartRect,
    required Color color,
  }) {
    if (points.length < 2) return;

    final path = Path();
    final first = _mapPoint(points.first, chartRect);
    path.moveTo(first.dx, chartRect.bottom);
    path.lineTo(first.dx, first.dy);

    for (int i = 1; i < points.length; i++) {
      final mapped = _mapPoint(points[i], chartRect);
      path.lineTo(mapped.dx, mapped.dy);
    }

    final last = _mapPoint(points.last, chartRect);
    path.lineTo(last.dx, chartRect.bottom);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawLine({
    required Canvas canvas,
    required List<_HourlyGraphPoint> points,
    required Rect chartRect,
    required Color color,
    required double strokeWidth,
  }) {
    if (points.length < 2) return;

    final path = Path();
    final first = _mapPoint(points.first, chartRect);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < points.length; i++) {
      final mapped = _mapPoint(points[i], chartRect);
      path.lineTo(mapped.dx, mapped.dy);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void _drawMarkers({
    required Canvas canvas,
    required List<_HourlyGraphPoint> points,
    required Rect chartRect,
    required Color color,
    required double radius,
  }) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      final offset = _mapPoint(point, chartRect);
      canvas.drawCircle(offset, radius, fillPaint);
      canvas.drawCircle(offset, radius, strokePaint);
    }
  }

  void _drawHoverGuide({
  required Canvas canvas,
  required Rect chartRect,
}) {
  final hour = hoveredCompletedHour;

  if (hour == null) return;

  final x = chartRect.left + (hour / 24.0) * chartRect.width;

  final guidePaint = Paint()
    ..color = todayColor.withOpacity(0.35)
    ..strokeWidth = 2;

  canvas.drawLine(
    Offset(x, chartRect.top),
    Offset(x, chartRect.bottom),
    guidePaint,
  );

  final todayPoint = _findPointAtHour(todayPoints, hour);
  final yesterdayPoint = _findPointAtHour(yesterdayPoints, hour);

  if (yesterdayPoint != null) {
    final offset = _mapPoint(yesterdayPoint, chartRect);

    final paint = Paint()
      ..color = yesterdayColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(offset, 7, paint);
  }

  if (todayPoint != null) {
    final offset = _mapPoint(todayPoint, chartRect);

    final paint = Paint()
      ..color = todayColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(offset, 8, paint);
  }
}

_HourlyGraphPoint? _findPointAtHour(
  List<_HourlyGraphPoint> points,
  int hour,
) {
  for (final point in points) {
    if ((point.hour - hour).abs() < 0.001) {
      return point;
    }
  }

  return null;
}

  Offset _mapPoint(_HourlyGraphPoint point, Rect chartRect) {
    final double safeMax = maxRevenue <= 0 ? 1.0 : maxRevenue;

    final double x =
        chartRect.left + (point.hour / 24.0) * chartRect.width;

    final double normalizedRevenue =
        ((point.revenue / safeMax).clamp(0.0, 1.0)).toDouble();

    final double y =
        chartRect.bottom - (normalizedRevenue * chartRect.height);

    return Offset(x, y);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _HourlyRevenueChartPainter oldDelegate) {
    return true;
  }
}

String _formatHourMinute(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatMoneyCompact(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M ₺';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K ₺';
  }

  return '${value.toStringAsFixed(0)} ₺';
}

class _GraphLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _GraphLegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

class _MiniGraphInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final double percentage;

  const _MiniGraphInfoCard({
    required this.title,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final bool positive = percentage >= 0;
    final Color color = positive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyHoverInfo {
  final int completedHour;
  final double todayValue;
  final double yesterdayValue;
  final double differenceAmount;
  final double percentage;

  const _HourlyHoverInfo({
    required this.completedHour,
    required this.todayValue,
    required this.yesterdayValue,
    required this.differenceAmount,
    required this.percentage,
  });
}

class _HourlyHoverTooltip extends StatelessWidget {
  final _HourlyHoverInfo info;

  const _HourlyHoverTooltip({
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final positive = info.percentage >= 0;
    final color = positive ? Colors.green : Colors.red;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Colors.transparent,
      child: Container(
        width: 255,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textDark.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '00:00 - ${info.completedHour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            _tooltipLine(
              label: 'Bugün',
              value: _formatMoneyLarge(info.todayValue),
            ),
            _tooltipLine(
              label: 'Dün',
              value: _formatMoneyLarge(info.yesterdayValue),
            ),
            const Divider(height: 18),
            _tooltipLine(
              label: 'Fark',
              value: _formatMoneyLarge(info.differenceAmount),
              valueColor: color,
            ),
            const SizedBox(height: 6),
            Text(
              '${positive ? '+' : ''}${info.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tooltipLine({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoneyLarge(double value) {
  return '${value.toStringAsFixed(0)} ₺';
}

String _formatFullDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');

  return '$day.$month.$year $hour:$minute:$second';
}

// --------------------------------------------------------------------
// GÜNLÜK ÖZET SAYFASI
// --------------------------------------------------------------------
class _DailySummaryPage extends StatefulWidget {
  const _DailySummaryPage();

  @override
  State<_DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<_DailySummaryPage> {
  bool isLoading = true;

  double todayTotal = 0;
  int todayReceiptsCount = 0;

  double todayCashTotal = 0;
  double todayCardTotal = 0;
  double todayPaidTotal = 0;
  double todayCashPercentage = 0;
  double todayCardPercentage = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyStats();
  }

  Future<void> _loadDailyStats() async {
    final todaysRevenue =
        await DatabaseService.instance.getTodaysBusinessRevenue();

    final paymentSummary =
        await DatabaseService.instance.getTodaysPaymentSummary();

    final allReceipts = await DatabaseService.instance.getAllReceipts();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    int count = 0;
    double cashTotal = 0;
    double cardTotal = 0;

    for (var r in allReceipts) {
      final dateStr = r['date_closed'] as String?;
      final date = DateTime.tryParse(dateStr ?? '');

      if (date != null &&
          !date.isBefore(todayStart) &&
          date.isBefore(todayEnd)) {
        count++;
      }
    }

    for (var row in paymentSummary) {
      final method = row['payment_method']?.toString();
      final amount = ((row['total_amount'] as num?) ?? 0).toDouble();

      if (method == 'cash') {
        cashTotal += amount;
      } else if (method == 'credit_card') {
        cardTotal += amount;
      }
    }

    final paidTotal = cashTotal + cardTotal;

    final cashPercentage = paidTotal == 0 ? 0 : (cashTotal / paidTotal) * 100;
    final cardPercentage = paidTotal == 0 ? 0 : (cardTotal / paidTotal) * 100;

    if (!mounted) return;

    setState(() {
      todayTotal = todaysRevenue;
      todayReceiptsCount = count;

      todayCashTotal = cashTotal;
      todayCardTotal = cardTotal;
      todayPaidTotal = paidTotal;
      todayCashPercentage = cashPercentage.toDouble();
      todayCardPercentage = cardPercentage.toDouble();

      isLoading = false;
    });
  }

  @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  return SizedBox.expand(
    child: Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bugünün Özeti',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bugün girilen tüm siparişleri gösterir. Açık, ödeme bekleyen ve kapanmış masalar dahildir.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                _buildDailyCard(
                  'Bugün Kapanan Masa',
                  todayReceiptsCount.toString(),
                  Icons.check_circle,
                  AppTheme.pastelGreen,
                ),
                const SizedBox(width: 24),
                _buildDailyCard(
                  'Bugünün Cirosu',
                  '${todayTotal.toStringAsFixed(2)} ₺',
                  Icons.attach_money,
                  AppTheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildPaymentBreakdownCard(),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDailyCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.22),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 42),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBreakdownCard() {
    final hasPayments = todayPaidTotal > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textMuted.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments, color: AppTheme.primary),
              const SizedBox(width: 10),
              const Text(
                'Ödeme Dağılımı',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bugün alınan ödemelerin nakit ve kredi kartı dağılımı.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          if (!hasPayments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Bugün henüz ödeme alınmadı.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodItem(
                    title: 'Nakit',
                    amount: todayCashTotal,
                    percentage: todayCashPercentage,
                    icon: Icons.money,
                    color: AppTheme.pastelGreen,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildPaymentMethodItem(
                    title: 'Kredi Kartı',
                    amount: todayCardTotal,
                    percentage: todayCardPercentage,
                    icon: Icons.credit_card,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required String title,
    required double amount,
    required double percentage,
    required IconData icon,
    required Color color,
  }) {
    final progressValue = (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${amount.toStringAsFixed(2)} ₺',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '%${percentage.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------
// TÜM SATIŞLAR SAYFASI
// --------------------------------------------------------------------
class _AllSalesPage extends StatefulWidget {
  const _AllSalesPage();

  @override
  State<_AllSalesPage> createState() => _AllSalesPageState();
}

class _AllSalesPageState extends State<_AllSalesPage> {
  List<Map<String, dynamic>> allReceipts = [];
  List<Map<String, dynamic>> filteredReceipts = [];
  bool isLoading = true;

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadSales();
  }

  Future<void> _loadSales() async {
    final data = await DatabaseService.instance.getAllReceipts();
    setState(() {
      allReceipts = data;
      _applyFilter();
      isLoading = false;
    });
  }

  void _applyFilter() {
    if (startDate == null || endDate == null) {
      filteredReceipts = allReceipts;
      return;
    }

    filteredReceipts = allReceipts.where((r) {
      final dateStr = r['date_closed'] as String?;
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return date.compareTo(startDate!) >= 0 && date.compareTo(endDate!) <= 0;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    DateTime tempStart = startDate ?? DateTime.now();
    DateTime tempEnd = endDate ?? DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Tarih Aralığı Seç', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: AppTheme.primary.withOpacity(0.05),
                      title: const Text('Başlangıç Tarihi', style: TextStyle(color: AppTheme.textMuted)),
                      subtitle: Text('${tempStart.day.toString().padLeft(2, '0')}.${tempStart.month.toString().padLeft(2, '0')}.${tempStart.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      trailing: const Icon(Icons.calendar_today, color: AppTheme.primary),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => tempStart = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: AppTheme.primary.withOpacity(0.05),
                      title: const Text('Bitiş Tarihi', style: TextStyle(color: AppTheme.textMuted)),
                      subtitle: Text('${tempEnd.day.toString().padLeft(2, '0')}.${tempEnd.month.toString().padLeft(2, '0')}.${tempEnd.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      trailing: const Icon(Icons.calendar_today, color: AppTheme.primary),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempEnd,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => tempEnd = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    if (tempStart.isAfter(tempEnd)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Başlangıç tarihi bitiş tarihinden sonra olamaz!'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {
        startDate = DateTime(tempStart.year, tempStart.month, tempStart.day);
        endDate = DateTime(tempEnd.year, tempEnd.month, tempEnd.day, 23, 59, 59);
        _applyFilter();
      });
    }
  }

  Future<void> _showSaleDetails(Map<String, dynamic> receipt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final items = await DatabaseService.instance.getReceiptItems(receipt['id'] as int);
    
    // ignore: use_build_context_synchronously
    Navigator.pop(context); // close loading

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) {
        final String detailTitle = receipt['table_code'] != null 
            ? '${receipt['table_code']} - ${receipt['table_name']} (${receipt['table_area']})' 
            : '${receipt['table_name']}';
        
        return AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Adisyon Detayı - $detailTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tarih: ${_formatDate(receipt['date_closed'])}', style: const TextStyle(color: AppTheme.textMuted)),
                const Divider(height: 32),
                const Text('Satılan Ürünler:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(item['quantity'] as num).toDouble() == (item['quantity'] as num).truncateToDouble() ? (item['quantity'] as num).toInt() : (item['quantity'] as num).toDouble()}x ${item['product_name']}'),
                            Text('${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)} ₺'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nakit Ödeme:', style: TextStyle(color: AppTheme.pastelGreen, fontWeight: FontWeight.bold)),
                    Text('${(receipt['cash_paid'] as num?)?.toStringAsFixed(2) ?? "0.00"} ₺', style: const TextStyle(color: AppTheme.pastelGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kart Ödeme:', style: TextStyle(color: AppTheme.pastelBlue, fontWeight: FontWeight.bold)),
                    Text('${(receipt['card_paid'] as num?)?.toStringAsFixed(2) ?? "0.00"} ₺', style: const TextStyle(color: AppTheme.pastelBlue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Toplam:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${(receipt['total_amount'] as num).toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String isoString) {
    final d = DateTime.tryParse(isoString);
    if (d == null) return isoString;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    double totalAmount = 0;
    double totalCash = 0;
    double totalCard = 0;
    for (var r in filteredReceipts) {
      totalAmount += (r['total_amount'] as num).toDouble();
      totalCash += (r['cash_paid'] as num?)?.toDouble() ?? 0.0;
      totalCard += (r['card_paid'] as num?)?.toDouble() ?? 0.0;
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tüm Satış Geçmişi',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      startDate != null && endDate != null
                          ? '${startDate!.day.toString().padLeft(2, '0')}.${startDate!.month.toString().padLeft(2, '0')}.${startDate!.year}  -  ${endDate!.day.toString().padLeft(2, '0')}.${endDate!.month.toString().padLeft(2, '0')}.${endDate!.year}'
                          : 'Tarih Seç',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() => isLoading = true);
                      _loadSales();
                    },
                    tooltip: 'Yenile',
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          
          // ÖZET KARTI
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Toplam Ciro', '${totalAmount.toStringAsFixed(2)} ₺', Icons.attach_money, AppTheme.primary),
                _buildSummaryStat('Masa (Adisyon)', '${filteredReceipts.length}', Icons.table_restaurant, AppTheme.textDark),
                _buildSummaryStat('Nakit', '${totalCash.toStringAsFixed(2)} ₺', Icons.money, AppTheme.pastelGreen),
                _buildSummaryStat('Kredi Kartı', '${totalCard.toStringAsFixed(2)} ₺', Icons.credit_card, AppTheme.pastelBlue),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
              ),
              child: filteredReceipts.isEmpty 
              ? const Center(child: Text('Bu tarih aralığında satış bulunmuyor.', style: TextStyle(color: AppTheme.textMuted, fontSize: 18)))
              : ListView.separated(
                itemCount: filteredReceipts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final r = filteredReceipts[index];
                  final String tableTitle = r['table_code'] != null 
                      ? '${r['table_code']} - ${r['table_name']}' 
                      : '${r['table_name']}';
                  
                  return ListTile(
                    onTap: () => _showSaleDetails(r),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.pastelGreen.withOpacity(0.2),
                      child: const Icon(Icons.receipt, color: AppTheme.pastelGreen),
                    ),
                    title: Text(tableTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tarih: ${_formatDate(r['date_closed'])}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(r['total_amount'] as num).toStringAsFixed(2)} ₺',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}

// --------------------------------------------------------------------
// ANALİTİK LOG SAYFASI
// --------------------------------------------------------------------
class _AnalyticsLogPage extends StatefulWidget {
  const _AnalyticsLogPage();

  @override
  State<_AnalyticsLogPage> createState() => _AnalyticsLogPageState();
}

class _AnalyticsLogPageState extends State<_AnalyticsLogPage> {
  bool isLoading = true;

  List<Map<String, dynamic>> recentSessions = [];
  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> topProducts = [];
  List<Map<String, dynamic>> topProductsByRevenue = [];
  List<Map<String, dynamic>> categoryRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      isLoading = true;
    });

    final sessions = await DatabaseService.instance.getRecentTableSessions();
    final orders = await DatabaseService.instance.getRecentOrderEvents();
    final productSales =
    await DatabaseService.instance.getTodaysProductSales();

final products = List<Map<String, dynamic>>.from(productSales);
products.sort((a, b) {
  final quantityCompare = _toDouble(b['total_quantity'])
      .compareTo(_toDouble(a['total_quantity']));

  if (quantityCompare != 0) {
    return quantityCompare;
  }

  return _toDouble(b['total_revenue'])
      .compareTo(_toDouble(a['total_revenue']));
});

final productsByRevenue = List<Map<String, dynamic>>.from(productSales);
productsByRevenue.sort((a, b) {
  final revenueCompare = _toDouble(b['total_revenue'])
      .compareTo(_toDouble(a['total_revenue']));

  if (revenueCompare != 0) {
    return revenueCompare;
  }

  return _toDouble(b['total_quantity'])
      .compareTo(_toDouble(a['total_quantity']));
});
    final categories = await DatabaseService.instance.getTodaysCategoryRevenue();

    if (!mounted) return;

    setState(() {
      recentSessions = sessions;
      recentOrders = orders;
      topProducts = products.take(20).toList();
      topProductsByRevenue = productsByRevenue.take(20).toList();
      categoryRevenue = categories;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Satış Verileri',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bugünün masa, ürün, kategori ve ödeme verilerini gösterir.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _loadAnalyticsData,
                icon: const Icon(Icons.refresh),
                label: const Text('Yenile'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.35,
              children: [
                _AnalyticsCard(
                  title: 'Masa Hareketleri',
                  icon: Icons.event_seat,
                  child: _SessionsList(data: recentSessions),
                ),
                _AnalyticsCard(
                  title: 'Son Siparişler',
                  icon: Icons.restaurant_menu,
                  child: _OrderEventsList(data: recentOrders),
                ),
                _AnalyticsCard(
                  title: 'Bugünün En Çok Satanları (Adet)',
                  icon: Icons.star,
                  child: _TopProductsList(
                    data: topProducts,
                    emphasizeQuantity: true,
                  ),
                ),
                _AnalyticsCard(
                  title: 'Bugünün En Çok Satanları (Ciro)',
                  icon: Icons.trending_up,
                  child: _TopProductsList(
                    data: topProductsByRevenue,
                    emphasizeQuantity: false,
                  ),
                ),
                _AnalyticsCard(
                  title: 'Bugünkü Kategori Cirosu',
                  icon: Icons.pie_chart,
                  child: _CategoryRevenueList(data: categoryRevenue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AnalyticsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textMuted.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SessionsList extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SessionsList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Henüz masa oturumu yok.'));
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        final sessionId = (item['id'] as num?)?.toInt();
        final totalOrdered = _toDouble(item['total_ordered']);
        final totalPaid = _toDouble(item['total_paid']);
        final remaining = totalOrdered - totalPaid;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            onTap: sessionId == null
                ? null
                : () {
                    _showSessionDetailsDialog(
                      context: context,
                      sessionId: sessionId,
                      session: item,
                    );
                  },
            title: Text(
              '${item['table_area']} - ${item['table_code']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Oturma: ${_formatDateTime(item['seated_at'])}\n'
              'Durum: ${item['status']}\n'
              '${_formatPaymentInfo(item)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMoney(totalOrdered),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (remaining > 0)
                  Text(
                    'Kalan: ${_formatMoney(remaining)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _showSessionDetailsDialog({
  required BuildContext context,
  required int sessionId,
  required Map<String, dynamic> session,
}) {
  final totalOrdered = _toDouble(session['total_ordered']);
  final totalPaid = _toDouble(session['total_paid']);
  final cashPaid = _toDouble(session['cash_paid']);
  final cardPaid = _toDouble(session['card_paid']);
  final remaining = totalOrdered - totalPaid;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          '${session['table_area']} - ${session['table_code']} Detay',
        ),
        content: SizedBox(
          width: 680,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseService.instance.getSessionOrderDetails(
              sessionId: sessionId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final orders = snapshot.data ?? [];

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SessionSummaryBox(
                        totalOrdered: totalOrdered,
                        totalPaid: totalPaid,
                        cashPaid: cashPaid,
                        cardPaid: cardPaid,
                        remaining: remaining,
                        seatedAt: session['seated_at'],
                        leftAt: session['left_at'],
                        status: session['status'],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sipariş Detayı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Bu oturum için sipariş detayı bulunamadı.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      else
                        ...orders.map((order) {
                          final quantity = _toDouble(order['total_quantity']);
                          final price = _toDouble(order['total_price']);

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              order['product_name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              order['product_category'].toString(),
                            ),
                            trailing: Text(
                              '${quantity == quantity.truncateToDouble() ? quantity.toInt() : quantity} adet / ${_formatMoney(price)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
}

class _SessionSummaryBox extends StatelessWidget {
  final double totalOrdered;
  final double totalPaid;
  final double cashPaid;
  final double cardPaid;
  final double remaining;
  final dynamic seatedAt;
  final dynamic leftAt;
  final dynamic status;

  const _SessionSummaryBox({
    required this.totalOrdered,
    required this.totalPaid,
    required this.cashPaid,
    required this.cardPaid,
    required this.remaining,
    required this.seatedAt,
    required this.leftAt,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final paidTotal = cashPaid + cardPaid;
    final cashPercentage = paidTotal == 0 ? 0 : (cashPaid / paidTotal) * 100;
    final cardPercentage = paidTotal == 0 ? 0 : (cardPaid / paidTotal) * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryLine('Durum', status?.toString() ?? '-'),
          _summaryLine('Oturma', _formatDateTime(seatedAt)),
          _summaryLine('Kalkış', _formatDateTime(leftAt)),
          const Divider(height: 20),
          _summaryLine('Toplam Sipariş', _formatMoney(totalOrdered)),
          _summaryLine('Toplam Ödenen', _formatMoney(totalPaid)),
          _summaryLine('Kalan', _formatMoney(remaining < 0 ? 0 : remaining)),
          const Divider(height: 20),
          _summaryLine(
            'Nakit',
            '${_formatMoney(cashPaid)} / %${cashPercentage.toStringAsFixed(1)}',
          ),
          _summaryLine(
            'Kredi Kartı',
            '${_formatMoney(cardPaid)} / %${cardPercentage.toStringAsFixed(1)}',
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderEventsList extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _OrderEventsList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Henüz sipariş logu yok.'));
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        final quantity = ((item['quantity_delta'] as num?) ?? 0).toDouble();
        final price = ((item['total_price'] as num?) ?? 0).toDouble();

        return ListTile(
          dense: true,
          title: Text(
            '${item['product_name']} x ${quantity == quantity.truncateToDouble() ? quantity.toInt() : quantity}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${item['table_area']} - ${item['table_code']} | ${item['product_category']}\n${_formatDateTime(item['created_at'])}',
          ),
          trailing: Text('${price.toStringAsFixed(0)} ₺'),
        );
      },
    );
  }
}

class _PaymentEventsList extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _PaymentEventsList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Henüz ödeme logu yok.'));
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        final amount = ((item['amount'] as num?) ?? 0).toDouble();

        return ListTile(
          dense: true,
          leading: Icon(
            item['payment_method'] == 'cash'
                ? Icons.payments
                : Icons.credit_card,
          ),
          title: Text(
            '${amount.toStringAsFixed(0)} ₺',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${item['table_area']} - ${item['table_code']} | ${item['payment_method']}\n${_formatDateTime(item['created_at'])}',
          ),
        );
      },
    );
  }
}

class _TopProductsList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool emphasizeQuantity;

  const _TopProductsList({
    required this.data,
    required this.emphasizeQuantity,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Bugün ürün satışı yok.'));
    }

    final totalQuantity = data.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['total_quantity']),
    );

    final totalRevenue = data.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['total_revenue']),
    );

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        final quantity = _toDouble(item['total_quantity']);
        final revenue = _toDouble(item['total_revenue']);

        final quantityPercentage =
            totalQuantity == 0 ? 0 : (quantity / totalQuantity) * 100;

        final revenuePercentage =
            totalRevenue == 0 ? 0 : (revenue / totalRevenue) * 100;

        if (emphasizeQuantity) {
          return ListTile(
            dense: true,
            title: Text(
              item['product_name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item['product_category']} | '
              'Ciro: ${_formatMoney(revenue)} | '
              'Ciro payı: %${revenuePercentage.toStringAsFixed(1)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${quantity == quantity.truncateToDouble() ? quantity.toInt() : quantity} adet',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Adet payı: %${quantityPercentage.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return ListTile(
          dense: true,
          title: Text(
            item['product_name'].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${item['product_category']} | '
            '${quantity == quantity.truncateToDouble() ? quantity.toInt() : quantity} adet | '
            'Adet payı: %${quantityPercentage.toStringAsFixed(1)}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(revenue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                'Ciro payı: %${revenuePercentage.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryRevenueList extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _CategoryRevenueList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Bugün kategori cirosu yok.'));
    }

    final totalQuantity = data.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['total_quantity']),
    );

    final totalRevenue = data.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['total_revenue']),
    );

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        final quantity = _toDouble(item['total_quantity']);
        final revenue = _toDouble(item['total_revenue']);

        final quantityPercentage =
            totalQuantity == 0 ? 0 : (quantity / totalQuantity) * 100;

        final revenuePercentage =
            totalRevenue == 0 ? 0 : (revenue / totalRevenue) * 100;

        return ListTile(
          dense: true,
          title: Text(
            item['product_category'].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${quantity == quantity.truncateToDouble() ? quantity.toInt() : quantity} ürün | '
            'Adet payı: %${quantityPercentage.toStringAsFixed(1)}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(revenue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ciro payı: %${revenuePercentage.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDateTime(dynamic value) {
  if (value == null) return '-';

  final parsed = DateTime.tryParse(value.toString());

  if (parsed == null) return value.toString();

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  final second = parsed.second.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute:$second';
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _formatMoney(dynamic value) {
  final amount = _toDouble(value);
  return '${amount.toStringAsFixed(2)} ₺';
}

String _formatPaymentInfo(Map<String, dynamic> item) {
  final totalPaid = _toDouble(item['total_paid']);
  final cashPaid = _toDouble(item['cash_paid']);
  final cardPaid = _toDouble(item['card_paid']);

  if (totalPaid <= 0) {
    return 'Ödeme: Henüz ödeme alınmadı';
  }

  final cashPercentage = totalPaid == 0 ? 0 : (cashPaid / totalPaid) * 100;
  final cardPercentage = totalPaid == 0 ? 0 : (cardPaid / totalPaid) * 100;

  return 'Ödeme: ${_formatMoney(totalPaid)} | '
      'Nakit ${_formatMoney(cashPaid)} (%${cashPercentage.toStringAsFixed(1)}) | '
      'Kart ${_formatMoney(cardPaid)} (%${cardPercentage.toStringAsFixed(1)})';
}

// --------------------------------------------------------------------
// HAFTALIK SATIŞ VERİLERİ SAYFASI
// --------------------------------------------------------------------
class _WeeklySalesDataPage extends StatelessWidget {
  const _WeeklySalesDataPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Haftalık Satış Verileri',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Haftalık ciro, ürün/kategori dağılımı ve ortalama masa hesabı burada gösterilecek.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}



// --------------------------------------------------------------------
// TEST VERİSİ OLUŞTURMA SAYFASI
// --------------------------------------------------------------------
class _MockDataPage extends StatefulWidget {
  final RestaurantController controller;
  const _MockDataPage({required this.controller});

  @override
  State<_MockDataPage> createState() => _MockDataPageState();
}

class _MockDataPageState extends State<_MockDataPage> {
  bool isGenerating = false;

  Future<void> _generateData() async {
    setState(() => isGenerating = true);
    final db = await DatabaseService.instance.database;
    final random = dart_math.Random();
    final now = DateTime.now();

    for (int i = 0; i < 100; i++) {
      final daysAgo = random.nextInt(365);
      final hour = random.nextInt(14) + 10; // 10:00 - 23:59
      final minute = random.nextInt(60);
      
      final date = now.subtract(Duration(days: daysAgo));
      final randomDate = DateTime(date.year, date.month, date.day, hour, minute);
      
      final table = widget.controller.tables[random.nextInt(widget.controller.tables.length)];
      
      final amount = 100 + random.nextInt(900).toDouble(); // 100.0 - 999.0
      final isCash = random.nextBool();
      final cashPaid = isCash ? amount : 0.0;
      final cardPaid = isCash ? 0.0 : amount;

      final receiptId = await db.insert('receipts', {
        'table_id': table.id,
        'table_code': table.code,
        'table_area': table.area,
        'table_name': table.name,
        'total_amount': amount,
        'total_paid': amount,
        'cash_paid': cashPaid,
        'card_paid': cardPaid,
        'date_closed': randomDate.toIso8601String(),
      });

      // Insert some random items
      final itemCount = random.nextInt(3) + 1;
      for (int j = 0; j < itemCount; j++) {
        final itemPrice = amount / itemCount;
        await db.insert('receipt_items', {
          'receipt_id': receiptId,
          'product_id': 'mock_${random.nextInt(100)}',
          'product_name': 'Örnek Ürün ${random.nextInt(100)}',
          'product_category': 'Yiyecek',
          'quantity': 1,
          'price': itemPrice,
        });
      }
    }

    setState(() => isGenerating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçmişe dönük 100 adet rastgele satış eklendi!'), backgroundColor: AppTheme.pastelGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isGenerating 
        ? const CircularProgressIndicator()
        : ElevatedButton.icon(
            icon: const Icon(Icons.add_chart),
            label: const Text('100 Rastgele Satış Ekle (Son 1 Yıl)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: widget.controller.tables.isEmpty ? null : _generateData,
          ),
    );
  }
}

