import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../theme/theme.dart';
import '../services/database_service.dart';


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

        return Padding(
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
            ],
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
// GÜNLÜK ÖZET SAYFASI
// --------------------------------------------------------------------
class _DailySummaryPage extends StatefulWidget {
  const _DailySummaryPage();

  @override
  State<_DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<_DailySummaryPage> {
  double todayTotal = 0;
  int todayReceiptsCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyStats();
  }

  Future<void> _loadDailyStats() async {
    final allReceipts = await DatabaseService.instance.getAllReceipts();
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    double sum = 0;
    int count = 0;

    for (var r in allReceipts) {
      final dateStr = r['date_closed'] as String;
      final date = DateTime.tryParse(dateStr);
      if (date != null && date.isAfter(todayStart)) {
        sum += (r['total_amount'] as num).toDouble();
        count++;
      }
    }

    setState(() {
      todayTotal = sum;
      todayReceiptsCount = count;
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
          const Text(
            'Günlük Özet (Bugün)',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sadece bugün kapatılmış olan adisyonların toplam özetini gösterir.',
            style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildDailyCard('Bugün Kapanan Masa', todayReceiptsCount.toString(), Icons.check_circle, AppTheme.pastelGreen),
              const SizedBox(width: 24),
              _buildDailyCard('Bugünkü Toplam Ciro', '${todayTotal.toStringAsFixed(2)} ₺', Icons.attach_money, AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
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
      
      return date.isAfter(startDate!) && date.isBefore(endDate!);
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: startDate != null && endDate != null 
          ? DateTimeRange(start: startDate!, end: endDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
        startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
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
        return AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Adisyon Detayı - ${receipt['table_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            Text('${item['quantity']}x ${item['product_name']}'),
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
                    Text('${(receipt['cash_paid'] as num).toStringAsFixed(2)} ₺', style: const TextStyle(color: AppTheme.pastelGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kart Ödeme:', style: TextStyle(color: AppTheme.pastelBlue, fontWeight: FontWeight.bold)),
                    Text('${(receipt['card_paid'] as num).toStringAsFixed(2)} ₺', style: const TextStyle(color: AppTheme.pastelBlue, fontWeight: FontWeight.bold)),
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
      totalCash += (r['cash_paid'] as num).toDouble();
      totalCard += (r['card_paid'] as num).toDouble();
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
                          ? '${startDate!.day}.${startDate!.month}.${startDate!.year} - ${endDate!.day}.${endDate!.month}.${endDate!.year}'
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
                  return ListTile(
                    onTap: () => _showSaleDetails(r),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.pastelGreen.withOpacity(0.2),
                      child: const Icon(Icons.receipt, color: AppTheme.pastelGreen),
                    ),
                    title: Text('${r['table_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
