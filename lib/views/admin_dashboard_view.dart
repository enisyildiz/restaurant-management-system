import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../theme/theme.dart';
import '../services/database_service.dart';
import 'dart:async';
import '../utils/money_formatter.dart';
import 'widgets/user_management_page.dart';
import 'product_analytics_view.dart';

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
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: Text('Ürün Analizleri'),
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
        return const ProductAnalyticsView();
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
        final activeTables = controller.tables
    .where((t) => t.status != TableStatus.empty)
    .toList();

    final activeOrderAmount = activeTables.fold<double>(0.0, (sum, table) {
      final paidAmount = table.totalCashPaid + table.totalCardPaid;
      final discountedTotal = table.currentTotal - table.totalDiscount;
      final remainingLiveAmount = discountedTotal - paidAmount;

      if (remainingLiveAmount <= 0) {
        return sum;
      }

      return sum + remainingLiveAmount;
    });

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
                    _buildStatCard('Açık Sipariş Toplamı', MoneyFormatter.formatTl(activeOrderAmount), Icons.receipt_long, AppTheme.pastelYellow),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 600,
                  child: _LiveHourlyComparisonGraph(controller: controller),
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
  final RestaurantController controller;

  const _LiveHourlyComparisonGraph({
    required this.controller,
  });

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

    widget.controller.addListener(_handleControllerChanged);

    _loadGraphData();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadGraphData();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _handleControllerChanged() {
  if (!mounted) return;

  setState(() {
    lastUpdated = DateTime.now();
  });
}

double _activeOpenRemainingRevenue() {
  final activeTables = widget.controller.tables.where(
    (table) => table.status != TableStatus.empty,
  );

  double total = 0;

  for (final table in activeTables) {
    final paidAmount = table.totalCashPaid + table.totalCardPaid;
    final discountedTotal = table.currentTotal - table.totalDiscount;
    final remainingLiveAmount = discountedTotal - paidAmount;

    if (remainingLiveAmount > 0) {
      total += remainingLiveAmount;
    }
  }

  return total;
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

  return rawHour.clamp(1, 24).toInt();
}

_HourlyHoverInfo _buildHoverInfo(int completedHour) {
  final isFutureHour = completedHour > lastUpdated.hour + 1;
  final yesterdayValue = _sumUntilHour(yesterdayHourly, completedHour);

  if (isFutureHour) {
    return _HourlyHoverInfo(
      completedHour: completedHour,
      todayValue: null,
      yesterdayValue: yesterdayValue,
      differenceAmount: null,
      percentage: null,
    );
  }

  double todayValue = _sumUntilHour(todayHourly, completedHour);
  if (completedHour == lastUpdated.hour + 1) {
    todayValue += _activeOpenRemainingRevenue();
  }

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

  final mouseX = chartLeft + (completedHour / 24.0) * chartWidth;

  final isMouseOnLeftHalf = mouseX < (size.width / 2);

  final tooltipX = isMouseOnLeftHalf
      ? size.width - 270
      : leftPadding + 12;

  return Offset(
    tooltipX.clamp(12.0, size.width - 270).toDouble(),
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
    cumulative += _activeOpenRemainingRevenue();

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

  final todayCurrentHour =
    todayHourly[lastUpdated.hour] + _activeOpenRemainingRevenue();
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

  _HourlyGraphPoint? todayPoint = _findPointAtHour(todayPoints, hour);
  if (todayPoint == null && todayPoints.isNotEmpty && hour == todayPoints.last.hour.ceil()) {
    todayPoint = todayPoints.last;
  }

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

String _formatMoneyCompact(num value) {
  return MoneyFormatter.formatTl(value);
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
  final double? todayValue;
  final double yesterdayValue;
  final double? differenceAmount;
  final double? percentage;

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
    final positive = (info.percentage ?? 0) >= 0;
    final color = info.percentage != null
        ? (positive ? Colors.green : Colors.red)
        : AppTheme.textMuted;

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
              value: info.todayValue == null ? '-' : _formatMoneyLarge(info.todayValue!),
            ),
            _tooltipLine(
              label: 'Dün',
              value: _formatMoneyLarge(info.yesterdayValue),
            ),
            if (info.differenceAmount != null && info.percentage != null) ...[
              const Divider(height: 18),
              _tooltipLine(
                label: 'Fark',
                value: _formatMoneyLarge(info.differenceAmount!),
                valueColor: color,
              ),
              const SizedBox(height: 6),
              Text(
                '${positive ? '+' : ''}${info.percentage!.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

String _formatMoneyLarge(num value) {
  return MoneyFormatter.formatTl(value);
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
                  MoneyFormatter.formatTl(todayTotal),
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
            MoneyFormatter.formatTl(amount),
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

  final TextEditingController tableFilterController = TextEditingController();

  bool filterCash = false;
  bool filterCard = false;
  bool filterDiscounted = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadSales();
  }

  @override
  void dispose() {
    tableFilterController.dispose();
    super.dispose();
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
  final tableFilter = tableFilterController.text.trim().toLowerCase();

  filteredReceipts = allReceipts.where((r) {
    final dateStr = r['date_closed'] as String?;
    if (dateStr == null) return false;

    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;

    if (startDate != null && date.compareTo(startDate!) < 0) {
      return false;
    }

    if (endDate != null && date.compareTo(endDate!) > 0) {
      return false;
    }

    if (tableFilter.isNotEmpty) {
      final tableCode = r['table_code']?.toString().toLowerCase() ?? '';
      final tableName = r['table_name']?.toString().toLowerCase() ?? '';
      final tableArea = r['table_area']?.toString().toLowerCase() ?? '';

      final combined = '$tableCode $tableName $tableArea';

      if (!combined.contains(tableFilter)) {
        return false;
      }
    }

    final cashPaid = _toDouble(r['cash_paid']);
    final cardPaid = _toDouble(r['card_paid']);
    final discountAmount = _toDouble(r['discount_amount']);

    if (filterCash && cashPaid <= 0) {
      return false;
    }

    if (filterCard && cardPaid <= 0) {
      return false;
    }

    if (filterDiscounted && discountAmount <= 0) {
      return false;
    }

        return true;
  }).toList();
}

Widget _buildFilterChip({
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
}) {
  return FilterChip(
    selected: selected,
    avatar: Icon(
      icon,
      size: 18,
      color: selected ? Colors.white : AppTheme.primary,
    ),
    label: Text(label),
    onSelected: (_) => onTap(),
    selectedColor: AppTheme.primary,
    checkmarkColor: Colors.white,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppTheme.textDark,
      fontWeight: FontWeight.w700,
    ),
    backgroundColor: Colors.white,
    side: BorderSide(
      color: selected ? AppTheme.primary : AppTheme.textMuted.withOpacity(0.25),
    ),
  );
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

        final netTotal = _toDouble(receipt['total_amount']);
        final cashPaid = _toDouble(receipt['cash_paid']);
        final cardPaid = _toDouble(receipt['card_paid']);
        final discountAmount = _toDouble(receipt['discount_amount']);

        final grossTotal = items.fold<double>(0, (sum, item) {
          final quantity = (item['quantity'] as num).toDouble();
          final price = (item['price'] as num).toDouble();

          return sum + (price * quantity);
        });

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

                      final quantity = (item['quantity'] as num).toDouble();
                      final quantityText = quantity == quantity.truncateToDouble()
                          ? quantity.toInt().toString()
                          : quantity.toString();

                      final price = (item['price'] as num).toDouble();
                      final lineTotal = price * quantity;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$quantityText x ${item['product_name']}'),
                            Text(MoneyFormatter.formatTl(lineTotal)),
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
    const Text(
      'Ara Toplam:',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    Text(
      MoneyFormatter.formatTl(grossTotal),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ],
),

if (discountAmount > 0) ...[
  const SizedBox(height: 8),
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Tanımlanan İndirim:',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        '-${MoneyFormatter.formatTl(discountAmount)}',
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
],

const SizedBox(height: 8),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Nakit Ödeme:',
      style: TextStyle(
        color: AppTheme.pastelGreen,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      MoneyFormatter.formatTl(cashPaid),
      style: const TextStyle(
        color: AppTheme.pastelGreen,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),

const SizedBox(height: 8),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Kart Ödeme:',
      style: TextStyle(
        color: AppTheme.pastelBlue,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      MoneyFormatter.formatTl(cardPaid),
      style: const TextStyle(
        color: AppTheme.pastelBlue,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),

const Divider(height: 32),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Net Toplam:',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    Text(
      MoneyFormatter.formatTl(netTotal),
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
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
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    ),
    Row(
      children: [
        OutlinedButton.icon(
          onPressed: _selectDateRange,
          icon: const Icon(Icons.calendar_month),
          label: Text(
            '${startDate!.day.toString().padLeft(2, '0')}.${startDate!.month.toString().padLeft(2, '0')}.${startDate!.year}'
            '  -  '
            '${endDate!.day.toString().padLeft(2, '0')}.${endDate!.month.toString().padLeft(2, '0')}.${endDate!.year}',
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _loadSales,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
  ],
),

const SizedBox(height: 24),

Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppTheme.surfaceLight,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppTheme.textMuted.withOpacity(0.12),
    ),
  ),
  child: Row(
    children: [
      SizedBox(
        width: 260,
        child: TextField(
          controller: tableFilterController,
          decoration: InputDecoration(
            labelText: 'Masa / Bölge Ara',
            hintText: 'Örn: B-10, Bahçe, S-1',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: tableFilterController.text.trim().isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        tableFilterController.clear();
                        _applyFilter();
                      });
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            isDense: true,
          ),
          onChanged: (_) {
            setState(() {
              _applyFilter();
            });
          },
        ),
      ),
      const SizedBox(width: 16),
      _buildFilterChip(
        label: 'Nakit',
        icon: Icons.money,
        selected: filterCash,
        onTap: () {
          setState(() {
            filterCash = !filterCash;
            _applyFilter();
          });
        },
      ),
      const SizedBox(width: 8),
      _buildFilterChip(
        label: 'Kredi Kartı',
        icon: Icons.credit_card,
        selected: filterCard,
        onTap: () {
          setState(() {
            filterCard = !filterCard;
            _applyFilter();
          });
        },
      ),
      const SizedBox(width: 8),
      _buildFilterChip(
        label: 'İndirimli Masa',
        icon: Icons.discount,
        selected: filterDiscounted,
        onTap: () {
          setState(() {
            filterDiscounted = !filterDiscounted;
            _applyFilter();
          });
        },
      ),
      const Spacer(),
      TextButton.icon(
        onPressed: () {
          setState(() {
            tableFilterController.clear();
            filterCash = false;
            filterCard = false;
            filterDiscounted = false;
            _applyFilter();
          });
        },
        icon: const Icon(Icons.restart_alt),
        label: const Text('Filtreleri Temizle'),
      ),
    ],
  ),
),

const SizedBox(height: 24),

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
      _buildSummaryStat(
        'Toplam Ciro',
        MoneyFormatter.formatTl(totalAmount),
        Icons.attach_money,
        AppTheme.primary,
      ),
      _buildSummaryStat(
        'Masa (Adisyon)',
        '${filteredReceipts.length}',
        Icons.table_restaurant,
        AppTheme.textDark,
      ),
      _buildSummaryStat(
        'Nakit',
        MoneyFormatter.formatTl(totalCash),
        Icons.money,
        AppTheme.pastelGreen,
      ),
      _buildSummaryStat(
        'Kredi Kartı',
        MoneyFormatter.formatTl(totalCard),
        Icons.credit_card,
        AppTheme.pastelBlue,
      ),
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
                          MoneyFormatter.formatTl(r['total_amount'] as num),
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
  double dailyTotalQuantity = 0.0;
  double dailyTotalRevenueAmount = 0.0;

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

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final totalMetrics = 
        await DatabaseService.instance.getTotalSalesMetricsBetween(
      start: start,
      end: end,
    );

    if (!mounted) return;

    setState(() {
      recentSessions = sessions;
      recentOrders = orders;
      topProducts = products.take(20).toList();
      topProductsByRevenue = productsByRevenue.take(20).toList();
      categoryRevenue = categories;
      dailyTotalQuantity = totalMetrics['total_quantity'] ?? 0.0;
      dailyTotalRevenueAmount = totalMetrics['total_revenue'] ?? 0.0;
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
                    totalRestaurantQuantity: dailyTotalQuantity,
                    totalRestaurantRevenue: dailyTotalRevenueAmount,
                  ),
                ),
                _AnalyticsCard(
                  title: 'Bugünün En Çok Satanları (Ciro)',
                  icon: Icons.trending_up,
                  child: _TopProductsList(
                    data: topProductsByRevenue,
                    emphasizeQuantity: false,
                    totalRestaurantQuantity: dailyTotalQuantity,
                    totalRestaurantRevenue: dailyTotalRevenueAmount,
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
        final cashPaid = _toDouble(item['cash_paid']);
        final cardPaid = _toDouble(item['card_paid']);
        final discountAmount = _toDouble(item['discount_amount']);

        final realPaid = cashPaid + cardPaid;
        final netRequired = totalOrdered - discountAmount;
        final remaining = netRequired - realPaid;

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
  final cashPaid = _toDouble(session['cash_paid']);
  final cardPaid = _toDouble(session['card_paid']);
  final discountAmount = _toDouble(session['discount_amount']);

  final realPaid = cashPaid + cardPaid;
  final netRequired = totalOrdered - discountAmount;
  final remaining = netRequired - realPaid;

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
                        discountAmount: discountAmount,
                        netRequired: netRequired,
                        totalPaid: realPaid,
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
  final double discountAmount;
  final double netRequired;
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
  required this.discountAmount,
  required this.netRequired,
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

          if (discountAmount > 0)
            _summaryLine(
              'Tanımlanan İndirim',
              '-${_formatMoney(discountAmount)}',
            ),

          _summaryLine('Ödenmesi Gereken', _formatMoney(netRequired)),
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

      final quantityText = quantity == quantity.truncateToDouble()
          ? quantity.toInt().toString()
          : quantity.toString();

      return ListTile(
        dense: true,
        title: Text(
          '${item['product_name']} x $quantityText',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item['table_area']} - ${item['table_code']} | ${item['product_category']}\n${_formatDateTime(item['created_at'])}',
        ),
        trailing: Text(MoneyFormatter.formatTl(price)),
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
            MoneyFormatter.formatTl(amount),
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
  final double totalRestaurantQuantity;
  final double totalRestaurantRevenue;

  const _TopProductsList({
    required this.data,
    required this.emphasizeQuantity,
    this.totalRestaurantQuantity = 0.0,
    this.totalRestaurantRevenue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Bugün ürün satışı yok.'));
    }

    final totalQuantity = totalRestaurantQuantity > 0 
        ? totalRestaurantQuantity 
        : data.fold<double>(
            0,
            (sum, item) => sum + _toDouble(item['total_quantity']),
          );

    final totalRevenue = totalRestaurantRevenue > 0
        ? totalRestaurantRevenue
        : data.fold<double>(
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
  return MoneyFormatter.formatTl(amount);
}

String _formatPaymentInfo(Map<String, dynamic> item) {
  final cashPaid = _toDouble(item['cash_paid']);
  final cardPaid = _toDouble(item['card_paid']);
  final discountAmount = _toDouble(item['discount_amount']);

  final realPaid = cashPaid + cardPaid;

  if (realPaid <= 0 && discountAmount <= 0) {
    return 'Ödeme: Henüz ödeme alınmadı';
  }

  final cashPercentage = realPaid == 0 ? 0 : (cashPaid / realPaid) * 100;
  final cardPercentage = realPaid == 0 ? 0 : (cardPaid / realPaid) * 100;

  final discountText = discountAmount > 0
      ? ' | İndirim ${_formatMoney(discountAmount)}'
      : '';

  return 'Ödeme: ${_formatMoney(realPaid)}$discountText | '
      'Nakit ${_formatMoney(cashPaid)} (%${cashPercentage.toStringAsFixed(1)}) | '
      'Kart ${_formatMoney(cardPaid)} (%${cardPercentage.toStringAsFixed(1)})';
}

// --------------------------------------------------------------------
// HAFTALIK SATIŞ VERİLERİ SAYFASI
// --------------------------------------------------------------------
class _WeeklySalesDataPage extends StatefulWidget {
  const _WeeklySalesDataPage();

  @override
  State<_WeeklySalesDataPage> createState() => _WeeklySalesDataPageState();
}

class _WeeklySalesDataPageState extends State<_WeeklySalesDataPage> {
  Timer? _timer;

  bool isLoading = true;
  DateTime weekStart = DateTime.now();
  DateTime weekEnd = DateTime.now();
  DateTime lastUpdated = DateTime.now();

  List<_DailyMetricPoint> weeklyRevenue = [];
  List<_DailyMetricPoint> averageTableOrder = [];
  List<Map<String, dynamic>> weeklyProductSales = [];
  List<Map<String, dynamic>> weeklyCategoryRevenue = [];
  double weeklyTotalQuantity = 0.0;
  double weeklyTotalRevenueAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();

    _timer = Timer.periodic(const Duration(hours: 3), (_) {
      _loadWeeklyData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _startOfLast7Days(DateTime date) {
    final todayStart = DateTime(date.year, date.month, date.day);
    return todayStart.subtract(const Duration(days: 6));
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Pzt';
      case 2:
        return 'Sal';
      case 3:
        return 'Çar';
      case 4:
        return 'Per';
      case 5:
        return 'Cum';
      case 6:
        return 'Cmt';
      case 7:
        return 'Paz';
      default:
        return '-';
    }
  }

  List<_DailyMetricPoint> _buildDailyPoints({
    required DateTime start,
    required List<Map<String, dynamic>> rows,
    required String valueKey,
  }) {
    final valuesByDay = <String, double>{};

    for (final row in rows) {
      final day = row['day']?.toString();
      if (day == null) continue;

      valuesByDay[day] = _toDouble(row[valueKey]);
    }

    return List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final key = _dateKey(date);

      return _DailyMetricPoint(
        label: _weekdayShort(date.weekday),
        dateLabel:
            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}',
        value: valuesByDay[key] ?? 0,
      );
    });
  }

  Future<void> _loadWeeklyData() async {
    setState(() {
      isLoading = true;
    });

    final now = DateTime.now();
    final start = _startOfLast7Days(now);
    final end = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );

    final revenueRows =
        await DatabaseService.instance.getDailyBusinessRevenueRowsBetween(
      start: start,
      end: end,
    );

    final avgOrderRows =
        await DatabaseService.instance.getAverageTableOrderByDayBetween(
      start: start,
      end: end,
    );

    final products = await DatabaseService.instance.getProductSalesBetween(
      start: start,
      end: end,
      limit: 50,
    );

    final categories =
        await DatabaseService.instance.getCategoryRevenueBetween(
      start: start,
      end: end,
    );

    final totalMetrics = 
        await DatabaseService.instance.getTotalSalesMetricsBetween(
      start: start,
      end: end,
    );

    final revenuePoints = _buildDailyPoints(
      start: start,
      rows: revenueRows,
      valueKey: 'total_revenue',
    );

    final avgOrderPoints = _buildDailyPoints(
      start: start,
      rows: avgOrderRows,
      valueKey: 'avg_order',
    );

    if (!mounted) return;

    setState(() {
      weekStart = start;
      weekEnd = end;
      weeklyRevenue = revenuePoints;
      averageTableOrder = avgOrderPoints;
      weeklyProductSales = products;
      weeklyCategoryRevenue = categories;
      weeklyTotalQuantity = totalMetrics['total_quantity'] ?? 0.0;
      weeklyTotalRevenueAmount = totalMetrics['total_revenue'] ?? 0.0;
      lastUpdated = now;
      isLoading = false;
    });
  }

  @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  final weeklyTotal = weeklyRevenue.fold<double>(
    0,
    (sum, point) => sum + point.value,
  );

  final nonZeroAverageDays = averageTableOrder
      .where((point) => point.value > 0)
      .map((point) => point.value)
      .toList();

  final weeklyAverageTableOrder = nonZeroAverageDays.isEmpty
      ? 0.0
      : nonZeroAverageDays.reduce((a, b) => a + b) /
          nonZeroAverageDays.length;

  return LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 950;
      final chartHeight = constraints.maxWidth < 750 ? 360.0 : 420.0;
      final tableCardHeight = constraints.maxWidth < 750 ? 390.0 : 460.0;

      return SingleChildScrollView(
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
                        'Haftalık Satış Verileri',
                        style: TextStyle(
                          fontSize: isNarrow ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatDateShort(weekStart)} - ${_formatDateShort(weekEnd.subtract(const Duration(days: 1)))} arası son 7 günlük satış performansı.',
                        style: TextStyle(
                          fontSize: isNarrow ? 14 : 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isNarrow) ...[
                  Text(
                    'Son güncelleme: ${_formatFullDateTime(lastUpdated)}',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                IconButton(
                  onPressed: _loadWeeklyData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Yenile',
                ),
              ],
            ),

            if (isNarrow) ...[
              const SizedBox(height: 8),
              Text(
                'Son güncelleme: ${_formatFullDateTime(lastUpdated)}',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              height: chartHeight,
              child: _WeeklyMetricChartCard(
                title: 'Son 7 Gün Ciro',
                subtitle: 'Günlere göre toplam satış cirosu',
                summaryLabel: 'Son 7 Gün Toplam',
                summaryValue: _formatMoneyLarge(weeklyTotal),
                points: weeklyRevenue,
                lineColor: AppTheme.primary,
                valueFormatter: _formatMoney,
              ),
            ),

            const SizedBox(height: 24),

            if (isNarrow)
              Column(
                children: [
                  SizedBox(
                    height: tableCardHeight,
                    child: _AnalyticsCard(
                      title: 'Haftanın En Çok Ciro Getiren Ürünleri',
                      icon: Icons.trending_up,
                      child: _TopProductsList(
                        data: weeklyProductSales,
                        emphasizeQuantity: false,
                        totalRestaurantQuantity: weeklyTotalQuantity,
                        totalRestaurantRevenue: weeklyTotalRevenueAmount,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: tableCardHeight,
                    child: _AnalyticsCard(
                      title: 'Haftalık Kategori Cirosu',
                      icon: Icons.pie_chart,
                      child: _CategoryRevenueList(
                        data: weeklyCategoryRevenue,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                height: tableCardHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Haftanın En Çok Ciro Getiren Ürünleri',
                        icon: Icons.trending_up,
                        child: _TopProductsList(
                          data: weeklyProductSales,
                          emphasizeQuantity: false,
                          totalRestaurantQuantity: weeklyTotalQuantity,
                          totalRestaurantRevenue: weeklyTotalRevenueAmount,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _AnalyticsCard(
                        title: 'Haftalık Kategori Cirosu',
                        icon: Icons.pie_chart,
                        child: _CategoryRevenueList(
                          data: weeklyCategoryRevenue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              height: chartHeight,
              child: _WeeklyMetricChartCard(
                title: 'Son 7 Gün Ortalama Masa Hesabı',
                subtitle: 'Günlere göre ortalama masa/adisyon tutarı',
                summaryLabel: 'Son 7 Gün Ortalama',
                summaryValue: _formatMoneyLarge(weeklyAverageTableOrder),
                points: averageTableOrder,
                lineColor: AppTheme.pastelGreen,
                valueFormatter: _formatMoneyCompact,
              ),
            ),
          ],
        ),
      );
    },
  );
}
}

class _DailyMetricPoint {
  final String label;
  final String dateLabel;
  final double value;

  const _DailyMetricPoint({
    required this.label,
    required this.dateLabel,
    required this.value,
  });
}

class _WeeklyMetricChartCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String summaryLabel;
  final String summaryValue;
  final List<_DailyMetricPoint> points;
  final Color lineColor;
  final String Function(double value) valueFormatter;

  const _WeeklyMetricChartCard({
    required this.title,
    required this.subtitle,
    required this.summaryLabel,
    required this.summaryValue,
    required this.points,
    required this.lineColor,
    required this.valueFormatter,
  });

  @override
  State<_WeeklyMetricChartCard> createState() => _WeeklyMetricChartCardState();
}

class _WeeklyMetricChartCardState extends State<_WeeklyMetricChartCard> {
  int? hoveredIndex;

  int? _hoveredIndexFromPosition({
    required Offset localPosition,
    required Size size,
  }) {
    if (widget.points.isEmpty) return null;

    final leftPadding = _weeklyChartLeftPadding(size.width);
    const rightPadding = 26.0;
    const topPadding = 18.0;
    const bottomPadding = 52.0;

    final chartLeft = leftPadding;
    final chartRight = size.width - rightPadding;
    final chartTop = topPadding;
    final chartBottom = size.height - bottomPadding;
    final chartWidth = chartRight - chartLeft;

    if (chartWidth <= 0) return null;

    if (localPosition.dx < chartLeft ||
        localPosition.dx > chartRight ||
        localPosition.dy < chartTop ||
        localPosition.dy > chartBottom) {
      return null;
    }

    if (widget.points.length == 1) return 0;

    final relativeX = localPosition.dx - chartLeft;
    final rawIndex =
        ((relativeX / chartWidth) * (widget.points.length - 1)).round();

    return rawIndex.clamp(0, widget.points.length - 1).toInt();
  }

  Offset _tooltipOffsetForIndex({
    required int index,
    required Size size,
  }) {
    final leftPadding = _weeklyChartLeftPadding(size.width);
    const rightPadding = 26.0;

    final chartLeft = leftPadding;
    final chartRight = size.width - rightPadding;
    final chartWidth = chartRight - chartLeft;

    final mouseX = widget.points.length <= 1
        ? chartLeft
        : chartLeft + (index / (widget.points.length - 1)) * chartWidth;

    final isMouseOnLeftHalf = mouseX < (size.width / 2);

    final tooltipX = isMouseOnLeftHalf 
        ? size.width - 282 
        : leftPadding + 14;

    return Offset(
      tooltipX.clamp(12.0, size.width - 282).toDouble(),
      12,
    );
  }

  _WeeklyHoverInfo _buildHoverInfo(int index) {
    final point = widget.points[index];
    final previousPoint = index > 0 ? widget.points[index - 1] : null;

    final previousValue = previousPoint?.value ?? 0.0;
    final difference = point.value - previousValue;
    final percentage = _percentageDifferenceForWeekly(
      point.value,
      previousValue,
    );

    return _WeeklyHoverInfo(
      label: point.label,
      dateLabel: point.dateLabel,
      value: point.value,
      previousLabel: previousPoint?.label,
      previousDateLabel: previousPoint?.dateLabel,
      previousValue: previousValue,
      difference: difference,
      percentage: percentage,
      hasPrevious: previousPoint != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.points.fold<double>(
      0,
      (max, point) => dart_math.max(max, point.value),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 620;
          final chartSize = Size(
            constraints.maxWidth,
            constraints.maxHeight - (isSmall ? 116 : 104),
          );

          final hoverInfo = hoveredIndex == null
              ? null
              : _buildHoverInfo(hoveredIndex!);

          final tooltipOffset = hoveredIndex == null
              ? null
              : _tooltipOffsetForIndex(
                  index: hoveredIndex!,
                  size: chartSize,
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSmall)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.summaryLabel}: ${widget.summaryValue}',
                      style: TextStyle(
                        color: widget.lineColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.show_chart, color: widget.lineColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.summaryLabel,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.summaryValue,
                          style: TextStyle(
                            color: widget.lineColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 18),

              Expanded(
                child: MouseRegion(
                  onHover: (event) {
                    final index = _hoveredIndexFromPosition(
                      localPosition: event.localPosition,
                      size: chartSize,
                    );

                    if (index != hoveredIndex) {
                      setState(() {
                        hoveredIndex = index;
                      });
                    }
                  },
                  onExit: (_) {
                    setState(() {
                      hoveredIndex = null;
                    });
                  },
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: _WeeklyMetricChartPainter(
                          points: widget.points,
                          maxValue: dart_math.max(maxValue, 100.0) * 1.15,
                          lineColor: widget.lineColor,
                          valueFormatter: widget.valueFormatter,
                          hoveredIndex: hoveredIndex,
                        ),
                        child: const SizedBox.expand(),
                      ),

                      if (hoverInfo != null && tooltipOffset != null)
                        Positioned(
                          left: tooltipOffset.dx,
                          top: tooltipOffset.dy,
                          child: _WeeklyHoverTooltip(
                            info: hoverInfo,
                            valueFormatter: widget.valueFormatter,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyMetricChartPainter extends CustomPainter {
  final List<_DailyMetricPoint> points;
  final double maxValue;
  final Color lineColor;
  final String Function(double value) valueFormatter;
  final int? hoveredIndex;

  const _WeeklyMetricChartPainter({
    required this.points,
    required this.maxValue,
    required this.lineColor,
    required this.valueFormatter,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = _weeklyChartLeftPadding(size.width);
    const double rightPadding = 26;
    const double topPadding = 18;
    const double bottomPadding = 52;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      size.width - leftPadding - rightPadding,
      size.height - topPadding - bottomPadding,
    );

    final gridPaint = Paint()
      ..color = AppTheme.textMuted.withOpacity(0.12)
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = AppTheme.textMuted.withOpacity(0.35)
      ..strokeWidth = 1.2;

    for (int i = 0; i <= 4; i++) {
      final y = chartRect.bottom - (chartRect.height / 4) * i;
      final value = (maxValue / 4) * i;

      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );

      _drawText(
        canvas,
        valueFormatter(value),
        Offset(8, y - 8),
        AppTheme.textMuted,
        size.width < 620 ? 10 : 12,
        FontWeight.w500,
      );
    }

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

    if (points.isEmpty) return;

    for (int i = 0; i < points.length; i++) {
      final x = _xForIndex(i, chartRect);

      canvas.drawLine(
        Offset(x, chartRect.top),
        Offset(x, chartRect.bottom),
        gridPaint,
      );

      _drawText(
        canvas,
        points[i].label,
        Offset(x - 12, chartRect.bottom + 10),
        AppTheme.textDark,
        size.width < 620 ? 10 : 12,
        FontWeight.bold,
      );

      _drawText(
        canvas,
        points[i].dateLabel,
        Offset(x - 18, chartRect.bottom + 28),
        AppTheme.textMuted,
        size.width < 620 ? 9 : 11,
        FontWeight.w500,
      );
    }

    _drawFilledArea(canvas, chartRect);
    _drawLine(canvas, chartRect);
    _drawMarkers(canvas, chartRect);
    _drawHoverGuide(canvas, chartRect);
  }

  double _xForIndex(int index, Rect chartRect) {
    if (points.length == 1) {
      return chartRect.left;
    }

    return chartRect.left +
        (index / (points.length - 1)) * chartRect.width;
  }

  Offset _mapPoint(int index, Rect chartRect) {
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final x = _xForIndex(index, chartRect);
    final normalized =
        (points[index].value / safeMax).clamp(0.0, 1.0).toDouble();
    final y = chartRect.bottom - normalized * chartRect.height;

    return Offset(x, y);
  }

  void _drawFilledArea(Canvas canvas, Rect chartRect) {
    if (points.length < 2) return;

    final path = Path();
    final first = _mapPoint(0, chartRect);

    path.moveTo(first.dx, chartRect.bottom);
    path.lineTo(first.dx, first.dy);

    for (int i = 1; i < points.length; i++) {
      final point = _mapPoint(i, chartRect);
      path.lineTo(point.dx, point.dy);
    }

    final last = _mapPoint(points.length - 1, chartRect);
    path.lineTo(last.dx, chartRect.bottom);
    path.close();

    final paint = Paint()
      ..color = lineColor.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, Rect chartRect) {
    if (points.length < 2) return;

    final path = Path();
    final first = _mapPoint(0, chartRect);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < points.length; i++) {
      final point = _mapPoint(i, chartRect);
      path.lineTo(point.dx, point.dy);
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void _drawMarkers(Canvas canvas, Rect chartRect) {
    final fillPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final point = _mapPoint(i, chartRect);
      canvas.drawCircle(point, 5, fillPaint);
      canvas.drawCircle(point, 5, strokePaint);
    }
  }

  void _drawHoverGuide(Canvas canvas, Rect chartRect) {
    final index = hoveredIndex;

    if (index == null || index < 0 || index >= points.length) {
      return;
    }

    final x = _xForIndex(index, chartRect);

    final guidePaint = Paint()
      ..color = lineColor.withOpacity(0.35)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(x, chartRect.top),
      Offset(x, chartRect.bottom),
      guidePaint,
    );

    final point = _mapPoint(index, chartRect);

    final fillPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(point, 8, fillPaint);
    canvas.drawCircle(point, 8, strokePaint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyMetricChartPainter oldDelegate) {
    return true;
  }
}

class _WeeklyHoverInfo {
  final String label;
  final String dateLabel;
  final double value;
  final String? previousLabel;
  final String? previousDateLabel;
  final double previousValue;
  final double difference;
  final double percentage;
  final bool hasPrevious;

  const _WeeklyHoverInfo({
    required this.label,
    required this.dateLabel,
    required this.value,
    required this.previousLabel,
    required this.previousDateLabel,
    required this.previousValue,
    required this.difference,
    required this.percentage,
    required this.hasPrevious,
  });
}

class _WeeklyHoverTooltip extends StatelessWidget {
  final _WeeklyHoverInfo info;
  final String Function(double value) valueFormatter;

  const _WeeklyHoverTooltip({
    required this.info,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final positive = info.difference >= 0;
    final color = positive ? Colors.green : Colors.red;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: Colors.transparent,
      child: Container(
        width: 270,
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
              '${info.label} - ${info.dateLabel}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            _tooltipLine(
              label: 'Değer',
              value: valueFormatter(info.value),
            ),
            if (info.hasPrevious)
              _tooltipLine(
                label: 'Önceki',
                value:
                    '${info.previousLabel} ${info.previousDateLabel}: ${valueFormatter(info.previousValue)}',
              ),
            const Divider(height: 18),
            if (info.hasPrevious) ...[
              _tooltipLine(
                label: 'Fark',
                value: valueFormatter(info.difference),
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
            ] else
              const Text(
                'Karşılaştırma için önceki gün yok.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
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
            width: 66,
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

double _weeklyChartLeftPadding(double width) {
  if (width < 620) return 58.0;
  return 76.0;
}

double _percentageDifferenceForWeekly(double current, double previous) {
  if (previous == 0) {
    if (current == 0) return 0;
    return 100;
  }

  return ((current / previous) - 1) * 100;
}

String _formatDateShort(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month';
}

// --------------------------------------------------------------------
// TEST VERİSİ OLUŞTURMA SAYFASI
// --------------------------------------------------------------------


