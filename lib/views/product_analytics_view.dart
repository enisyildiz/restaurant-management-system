import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../theme/theme.dart';
import '../utils/money_formatter.dart';

class ProductAnalyticsView extends StatefulWidget {
  const ProductAnalyticsView({super.key});

  @override
  State<ProductAnalyticsView> createState() => _ProductAnalyticsViewState();
}

class _ProductAnalyticsViewState extends State<ProductAnalyticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  bool _isLoading = true;
  bool _sortByQuantity = true;

  // Data
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _dailyTrendData = [];
  List<Map<String, dynamic>> _hourlyHeatmapData = [];
  List<Map<String, dynamic>> _availableProducts = [];

  String? _selectedProductId;
  String _topProductsChartType = 'Çubuk Grafiği'; // Çubuk Grafiği, Pasta Grafiği
  String _categoryChartType = 'Halka Grafiği'; // Halka Grafiği, Pasta Grafiği
  String _trendChartType = 'Çizgi Grafiği'; // Çizgi Grafiği, Alan Grafiği

  int _touchedTopProductIndex = -1;
  int _touchedCategoryIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);

      final db = DatabaseService.instance;
      _availableProducts = await db.getAvailableProductsForAnalytics();
      
      _topProducts = await db.getProductSalesBetween(
        start: startOfDay,
        end: endOfDay,
        limit: 15,
        orderByQuantity: _sortByQuantity,
      );

      _categoryData = await db.getCategoryRevenueBetween(
        start: startOfDay,
        end: endOfDay,
      );

      _dailyTrendData = await db.getProductDailySalesTrendBetween(
        start: startOfDay,
        end: endOfDay,
        productId: _selectedProductId,
      );

      _hourlyHeatmapData = await db.getHourlyProductHeatmapBetween(
        start: startOfDay,
        end: endOfDay,
      );
    } catch (e) {
      debugPrint("Error loading analytics: \$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      initialEntryMode: DatePickerEntryMode.input,
      saveText: 'Kaydet',
      cancelText: 'İptal',
      helpText: 'Tarih Aralığı Seçin',
      fieldStartHintText: 'gg/aa/yyyy',
      fieldEndHintText: 'gg/aa/yyyy',
      fieldStartLabelText: 'Başlangıç Tarihi',
      fieldEndLabelText: 'Bitiş Tarihi',
      errorFormatText: 'Geçersiz format',
      errorInvalidText: 'Geçersiz tarih',
      errorInvalidRangeText: 'Geçersiz tarih aralığı',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceLight,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: "En Çok Satanlar", icon: Icon(Icons.leaderboard)),
            Tab(text: "Kategori Dağılımı", icon: Icon(Icons.pie_chart)),
            Tab(text: "Satış Trendi", icon: Icon(Icons.timeline)),
            Tab(text: "Saatlik Yoğunluk", icon: Icon(Icons.access_time_filled)),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTopProductsTab(),
                    _buildCategoryTab(),
                    _buildTrendTab(),
                    _buildHeatmapTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Ürün Analizleri",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    _buildMetricButton(true, "Adet Bazlı"),
                    _buildMetricButton(false, "Ciro Bazlı"),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showDateRangePicker,
                icon: const Icon(Icons.date_range, color: Colors.white),
                label: Text(
                  "${_formatDateTr(_startDate, includeYear: true)} - ${_formatDateTr(_endDate, includeYear: true)}",
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetricButton(bool isQuantity, String text) {
    final isSelected = _sortByQuantity == isQuantity;
    return GestureDetector(
      onTap: () {
        if (_sortByQuantity != isQuantity) {
          setState(() {
            _sortByQuantity = isQuantity;
          });
          _loadAllData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required String title, required Widget trailing, String? tooltipMessage}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (tooltipMessage != null) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: tooltipMessage,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        textStyle: const TextStyle(color: Colors.white, height: 1.5, fontSize: 13),
                        child: const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                      ),
                    ],
                  ],
                ),
                trailing,
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeDropdown(String currentValue, List<String> items, Function(String) onChanged) {
    return DropdownButton<String>(
      value: currentValue,
      underline: const SizedBox(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }

  // --- Tab 1: Top Products ---

  Widget _buildTopProductsTab() {
    if (_topProducts.isEmpty) return const Center(child: Text("Veri bulunamadı."));

    return _buildCard(
      title: "En Çok Satan Ürünler",
      tooltipMessage: "• Seçili tarih aralığında en çok satan ürünleri sıralar.\n• İptal ve iade edilen siparişler bu sayıdan otomatik olarak düşülür.\n• Sadece hesabı başarıyla kapatılmış masaları baz alır.",
      trailing: _buildChartTypeDropdown(_topProductsChartType, ['Çubuk Grafiği', 'Pasta Grafiği'], (val) {
        setState(() => _topProductsChartType = val);
      }),
      child: _topProductsChartType == 'Çubuk Grafiği'
          ? _buildTopProductsBarChart()
          : _buildTopProductsPieChart(),
    );
  }

  Widget _buildPieLegend(List<Map<String, dynamic>> items, int touchedIndex, List<Color> colorPalette) {
    if (touchedIndex == -1 || touchedIndex >= items.length) {
      return const Center(child: Text("Detay için grafiğin üstüne gelin", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)));
    }
    final item = items[touchedIndex];
    final name = item['product_name'] ?? item['product_category'] ?? 'Bilinmeyen';
    final qty = item['total_quantity'];
    final rev = item['total_revenue'];
    final color = colorPalette[touchedIndex % colorPalette.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 16),
          if (qty != null) Text("Miktar: $qty Adet", style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          if (rev != null) Text("Ciro: ${MoneyFormatter.formatTl(rev)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildTopProductsBarChart() {
    double maxValue = 0;
    for (var p in _topProducts) {
      double val = _sortByQuantity ? (p['total_quantity'] as num).toDouble() : (p['total_revenue'] as num).toDouble();
      if (val > maxValue) maxValue = val;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final p = _topProducts[group.x.toInt()];
              final val = _sortByQuantity ? "${p['total_quantity']} Adet" : MoneyFormatter.formatTl(p['total_revenue']);
              return BarTooltipItem(
                "${p['product_name']}\n$val",
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _topProducts.length) return const SizedBox();
                final name = _topProducts[value.toInt()]['product_name'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: 60,
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
              reservedSize: 56,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(_sortByQuantity ? value.toInt().toString() : MoneyFormatter.formatPlain(value), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_topProducts.length, (index) {
          final p = _topProducts[index];
          final val = _sortByQuantity ? (p['total_quantity'] as num).toDouble() : (p['total_revenue'] as num).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: AppTheme.primary,
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopProductsPieChart() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedTopProductIndex = -1;
                      return;
                    }
                    _touchedTopProductIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(_topProducts.length, (index) {
                final p = _topProducts[index];
                final val = _sortByQuantity ? (p['total_quantity'] as num).toDouble() : (p['total_revenue'] as num).toDouble();
                final color = Colors.primaries[index % Colors.primaries.length];
                final isTouched = index == _touchedTopProductIndex;
                return PieChartSectionData(
                  color: color,
                  value: val,
                  title: p['product_name'].toString().split(' ').first,
                  radius: isTouched ? 110 : 100,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  badgeWidget: _Badge(val.toStringAsFixed(0)),
                  badgePositionPercentageOffset: .98,
                );
              }),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildPieLegend(_topProducts, _touchedTopProductIndex, Colors.primaries),
        ),
      ],
    );
  }

  // --- Tab 2: Category Distribution ---

  Widget _buildCategoryTab() {
    if (_categoryData.isEmpty) return const Center(child: Text("Kategori verisi bulunamadı."));
    
    return _buildCard(
      title: "Kategori Dağılımı (Ciro)",
      tooltipMessage: "• Belirtilen tarih aralığındaki net gelirlerinizin kategorilere göre oransal dağılımını gösterir.\n• Restoranınızın hangi ürün grubundan daha çok para kazandığını analiz etmenizi sağlar.\n• İptaller ve iadeler toplam cirodan düşülerek hesaplanır.",
      trailing: _buildChartTypeDropdown(_categoryChartType, ['Halka Grafiği', 'Pasta Grafiği'], (val) {
        setState(() => _categoryChartType = val);
      }),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedCategoryIndex = -1;
                        return;
                      }
                      _touchedCategoryIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: _categoryChartType == 'Halka Grafiği' ? 80 : 0,
                sections: List.generate(_categoryData.length, (index) {
                  final c = _categoryData[index];
                  final val = (c['total_revenue'] as num).toDouble();
                  final color = Colors.accents[index % Colors.accents.length];
                  final isTouched = index == _touchedCategoryIndex;
                  final defaultRadius = _categoryChartType == 'Halka Grafiği' ? 60.0 : 140.0;
                  return PieChartSectionData(
                    color: color,
                    value: val,
                    title: c['product_category'],
                    radius: isTouched ? defaultRadius + 10.0 : defaultRadius,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildPieLegend(_categoryData, _touchedCategoryIndex, Colors.accents),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Daily Trend ---

  Widget _buildTrendTab() {
    return _buildCard(
      title: "Günlük Satış Trendi",
      tooltipMessage: "• Yalnızca hesabı ödenmiş (kapatılmış) masaları baz alır.\n• Satışlardan iade ve iptaller düşülerek 'Net Satış' hesaplanır.\n• Çizginin eksiye inmesi, o gün satıştan daha çok iade/iptal yapıldığı anlamına gelir.",
      trailing: Row(
        children: [
          DropdownButton<String?>(
            value: _selectedProductId,
            hint: const Text("Tüm Ürünler"),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text("Tüm Ürünler")),
              ..._availableProducts.map((p) => DropdownMenuItem<String?>(
                    value: p['product_id'].toString(),
                    child: Text(p['product_name']),
                  )),
            ],
            onChanged: (val) {
              setState(() => _selectedProductId = val);
              _loadAllData();
            },
          ),
          const SizedBox(width: 16),
          _buildChartTypeDropdown(_trendChartType, ['Çizgi Grafiği', 'Alan Grafiği'], (val) {
            setState(() => _trendChartType = val);
          }),
        ],
      ),
      child: _dailyTrendData.isEmpty 
        ? const Center(child: Text("Veri bulunamadı."))
        : _buildTrendLineChart(),
    );
  }

  Widget _buildTrendLineChart() {
    List<FlSpot> spots = [];
    double maxY = 0;
    double minY = 0;
    
    for (int i = 0; i < _dailyTrendData.length; i++) {
      final item = _dailyTrendData[i];
      final val = _sortByQuantity ? (item['total_quantity'] as num).toDouble() : (item['total_revenue'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
      if (val < minY) minY = val;
    }

    return LineChart(
      LineChartData(
        minY: minY < 0 ? minY * 1.2 : 0,
        maxY: maxY <= 0 ? 10 : maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: _trendChartType == 'Alan Grafiği',
              color: AppTheme.primary.withOpacity(0.3),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _dailyTrendData.length) return const SizedBox();
                final dateStr = _dailyTrendData[value.toInt()]['sale_date'] as String;
                final date = DateTime.parse(dateStr);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_formatDateTr(date), style: const TextStyle(fontSize: 10)),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(_sortByQuantity ? value.toInt().toString() : MoneyFormatter.formatPlain(value), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // --- Tab 4: Hourly Heatmap ---

  Widget _buildHeatmapTab() {
    if (_hourlyHeatmapData.isEmpty) return const Center(child: Text("Veri bulunamadı."));
    
    return _buildCard(
      title: "Saatlik Satış Yoğunluğu",
      tooltipMessage: "• Günün hangi saatlerinde daha çok satış yapıldığını gösterir.\n• Yoğun saatleri belirleyip personel sayısını ve mutfak hazırlıklarını bu saatlere göre optimize etmenizi sağlar.\n• Sadece kapatılmış masaların ilk sipariş anlarını dikkate alır.",
      trailing: const SizedBox(),
      child: _buildHeatmapBarChart(),
    );
  }

  Widget _buildHeatmapBarChart() {
    double maxValue = 0;
    Map<int, double> hourData = {};
    for (var item in _hourlyHeatmapData) {
      final h = item['sale_hour'] as int;
      final val = _sortByQuantity ? (item['total_quantity'] as num).toDouble() : (item['total_revenue'] as num).toDouble();
      hourData[h] = val;
      if (val > maxValue) maxValue = val;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("${value.toInt().toString().padLeft(2, '0')}:00", style: const TextStyle(fontSize: 10)),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(_sortByQuantity ? value.toInt().toString() : MoneyFormatter.formatPlain(value), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (index) {
          final val = hourData[index] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: val > (maxValue * 0.7) ? Colors.orange : AppTheme.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }


  String _formatDateTr(DateTime date, {bool includeYear = false}) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month];
    if (includeYear) {
      return "$day $month ${date.year}";
    }
    return "$day $month";
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
