import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/restaurant_controller.dart';
import '../services/database_service.dart';
import '../theme/theme.dart';

class CashRegisterView extends StatelessWidget {
  final RestaurantController controller;

  const CashRegisterView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = controller.currentUser?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Kasa'),
          backgroundColor: AppTheme.surfaceLight,
          foregroundColor: AppTheme.textDark,
        ),
        body: const Center(
          child: Text(
            'Bu sayfaya sadece yönetici erişebilir.',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Kasa'),
          backgroundColor: AppTheme.surfaceLight,
          foregroundColor: AppTheme.textDark,
          elevation: 1,
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(
                icon: Icon(Icons.receipt_long),
                text: 'Gider Hareketleri',
              ),
              Tab(
                icon: Icon(Icons.assessment),
                text: 'Kasa Raporu',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ExpenseMovementsPage(controller: controller),
            const _CashReportPage(),
          ],
        ),
      ),
    );
  }
}

class _ExpenseMovementsPage extends StatefulWidget {
  final RestaurantController controller;

  const _ExpenseMovementsPage({
    required this.controller,
  });

  @override
  State<_ExpenseMovementsPage> createState() => _ExpenseMovementsPageState();
}

class _ExpenseMovementsPageState extends State<_ExpenseMovementsPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  DateTime selectedExpenseDate = DateTime.now();

  List<Map<String, dynamic>> expenseReasons = [];
  List<Map<String, dynamic>> expensePaymentMethods = [];
  List<Map<String, dynamic>> selectedDateExpenses = [];

  int? selectedReasonId;
  int? selectedPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    amountController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await DatabaseService.instance.ensureCashRegisterSchema();


    final reasons = await DatabaseService.instance.getExpenseReasons();
    final paymentMethods =
        await DatabaseService.instance.getExpensePaymentMethods();

    final selectedDayStart = DateTime(
      selectedExpenseDate.year,
      selectedExpenseDate.month,
      selectedExpenseDate.day,
    );
    final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

    final expenses = await DatabaseService.instance.getExpenseEventsBetween(
      start: selectedDayStart,
      end: selectedDayEnd,
    );

    if (!mounted) return;

    setState(() {
      expenseReasons = reasons;
      expensePaymentMethods = paymentMethods;
      selectedDateExpenses = expenses;

      if (selectedReasonId == null && reasons.isNotEmpty) {
        selectedReasonId = _toNullableInt(reasons.first['id']);
      }

      if (selectedReasonId != null) {
        final stillExists = reasons.any(
          (reason) => _toNullableInt(reason['id']) == selectedReasonId,
        );

        if (!stillExists) {
          selectedReasonId =
              reasons.isEmpty ? null : _toNullableInt(reasons.first['id']);
        }
      }

      if (selectedPaymentMethodId == null && paymentMethods.isNotEmpty) {
        selectedPaymentMethodId = _toNullableInt(paymentMethods.first['id']);
      }

      if (selectedPaymentMethodId != null) {
        final stillExists = paymentMethods.any(
          (method) =>
              _toNullableInt(method['id']) == selectedPaymentMethodId,
        );

        if (!stillExists) {
          selectedPaymentMethodId = paymentMethods.isEmpty
              ? null
              : _toNullableInt(paymentMethods.first['id']);
        }
      }

      isLoading = false;
    });
  }

  Map<String, dynamic>? _selectedReason() {
    for (final reason in expenseReasons) {
      if (_toNullableInt(reason['id']) == selectedReasonId) {
        return reason;
      }
    }

    return null;
  }

  Map<String, dynamic>? _selectedPaymentMethod() {
    for (final method in expensePaymentMethods) {
      if (_toNullableInt(method['id']) == selectedPaymentMethodId) {
        return method;
      }
    }

    return null;
  }

  Future<void> _pickExpenseDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedExpenseDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      selectedExpenseDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    });

    await _loadData();
  }

  Future<void> _saveExpense() async {
    final amountText = amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    final reason = _selectedReason();
    final paymentMethod = _selectedPaymentMethod();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir gider tutarı girin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir gider sebebi seçin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ödeme yöntemi seçin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final now = DateTime.now();
    final createdAt = DateTime(
      selectedExpenseDate.year,
      selectedExpenseDate.month,
      selectedExpenseDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    await DatabaseService.instance.insertExpenseEvent(
      reasonId: _toNullableInt(reason['id']),
      reasonName: reason['name'].toString(),
      paymentMethodId: _toNullableInt(paymentMethod['id']),
      paymentMethodName: paymentMethod['name'].toString(),
      amount: amount,
      createdAt: createdAt,
      comment: commentController.text.trim().isEmpty
          ? null
          : commentController.text.trim(),
      username: widget.controller.currentUser?.username,
      userRole: widget.controller.currentUser?.role.name,
    );

    amountController.clear();
    commentController.clear();

    await _loadData();

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gider kaydedildi.'),
        backgroundColor: AppTheme.pastelGreen,
      ),
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> item) async {
  final expenseId = _toNullableInt(item['id']);

  if (expenseId == null) {
    return;
  }

  final reasonName = item['reason_name']?.toString() ?? 'Gider';
  final amount = _toDouble(item['amount']);

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Gider kaydı silinsin mi?'),
        content: Text(
          '$reasonName - ${_formatMoney(amount)} gider kaydı silinecek.\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      );
    },
  );

  if (confirm != true) {
    return;
  }

  await DatabaseService.instance.deleteExpenseEvent(expenseId);
  await _loadData();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Gider kaydı silindi.'),
      backgroundColor: AppTheme.pastelGreen,
    ),
  );
}

  Future<void> _openReasonSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ExpenseReasonSettingsDialog(
        onChanged: _loadData,
      ),
    );

    await _loadData();
  }

  Future<void> _openPaymentMethodSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ExpensePaymentMethodSettingsDialog(
        onChanged: _loadData,
      ),
    );

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedDateTotalExpense = selectedDateExpenses.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['amount']),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gider Hareketleri',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: isNarrow ? 24 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kasadan çıkan giderleri tarih, ödeme yöntemi, sebep ve açıklama ile kaydedin.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: isNarrow ? 14 : 16,
                ),
              ),
              const SizedBox(height: 24),

              if (isNarrow)
                Column(
                  children: [
                    _buildExpenseForm(),
                    const SizedBox(height: 20),
                    _buildSelectedDateExpenseList(selectedDateTotalExpense),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 430,
                      child: _buildExpenseForm(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildSelectedDateExpenseList(
                        selectedDateTotalExpense,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(22),
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
          const Text(
            'Yeni Gider Kaydı',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildDateSelector(),

          const SizedBox(height: 16),

          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Tutar',
              hintText: 'Örn: 1250',
              suffixText: '₺',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            value: selectedReasonId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Gider Sebebi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: expenseReasons
                .where((reason) => _toNullableInt(reason['id']) != null)
                .map((reason) {
              final reasonId = _toNullableInt(reason['id'])!;

              return DropdownMenuItem<int>(
                value: reasonId,
                child: Text(reason['name'].toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedReasonId = value;
              });
            },
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openReasonSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Gider Sebeplerini Düzenle'),
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            value: selectedPaymentMethodId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Ödeme Yöntemi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: expensePaymentMethods
                .where((method) => _toNullableInt(method['id']) != null)
                .map((method) {
              final methodId = _toNullableInt(method['id'])!;

              return DropdownMenuItem<int>(
                value: methodId,
                child: Text(method['name'].toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPaymentMethodId = value;
              });
            },
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openPaymentMethodSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Ödeme Yöntemlerini Düzenle'),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: commentController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Açıklama / Yorum',
              hintText: 'İsteğe bağlı açıklama girin.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : _saveExpense,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Kaydediliyor...' : 'Gideri Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickExpenseDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Gider Tarihi',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text(
          _formatDateOnly(selectedExpenseDate),
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateExpenseList(double selectedDateTotalExpense) {
    return Container(
      height: 620,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(22),
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
              const Icon(Icons.today, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_formatDateOnly(selectedExpenseDate)} Giderleri',
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatMoney(selectedDateTotalExpense),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          if (selectedDateExpenses.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Seçili tarihte gider kaydı yok.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: selectedDateExpenses.length,
                itemBuilder: (context, index) {
                  final item = selectedDateExpenses[index];
                  final amount = _toDouble(item['amount']);
                  final comment = item['comment']?.toString();
                  final paymentMethod =
                      item['payment_method_name']?.toString() ??
                          'Belirtilmedi';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Gideri sil',
                        onPressed: () => _deleteExpense(item),
                      ),
                      title: Text(
                        item['reason_name'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      subtitle: Text(
                        '${_formatDateTime(item['created_at'])} | $paymentMethod'
                        '${comment == null || comment.trim().isEmpty ? '' : '\n$comment'}',
                      ),
                      trailing: Text(
                        _formatMoney(amount),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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

class _ExpenseReasonSettingsDialog extends StatefulWidget {
  final Future<void> Function() onChanged;

  const _ExpenseReasonSettingsDialog({
    required this.onChanged,
  });

  @override
  State<_ExpenseReasonSettingsDialog> createState() =>
      _ExpenseReasonSettingsDialogState();
}

class _ExpenseReasonSettingsDialogState
    extends State<_ExpenseReasonSettingsDialog> {
  bool isLoading = true;
  List<Map<String, dynamic>> reasons = [];

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    final data = await DatabaseService.instance.getExpenseReasons();

    if (!mounted) return;

    setState(() {
      reasons = data;
      isLoading = false;
    });
  }

  Future<String?> _showReasonNameDialog({
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          title: Text(
            initialValue == null
                ? 'Yeni Gider Sebebi'
                : 'Gider Sebebini Düzenle',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Sebep adı',
              hintText: 'Örn: Mutfak Alışverişi',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _addReason() async {
    final name = await _showReasonNameDialog();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await DatabaseService.instance.addExpenseReason(name);
    await _loadReasons();
    await widget.onChanged();
  }

  Future<void> _editReason(Map<String, dynamic> reason) async {
    final reasonId = _toNullableInt(reason['id']);

    if (reasonId == null) {
      return;
    }

    final name = await _showReasonNameDialog(
      initialValue: reason['name'].toString(),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await DatabaseService.instance.updateExpenseReason(
      reasonId: reasonId,
      name: name,
    );

    await _loadReasons();
    await widget.onChanged();
  }

  Future<void> _deleteReason(Map<String, dynamic> reason) async {
    final reasonId = _toNullableInt(reason['id']);

    if (reasonId == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          title: const Text('Gider sebebi silinsin mi?'),
          content: Text(
            '"${reason['name']}" artık yeni gider girişlerinde görünmeyecek. Eski gider kayıtları korunacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await DatabaseService.instance.deactivateExpenseReason(reasonId);
    await _loadReasons();
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceLight,
      title: const Text('Gider Sebepleri'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addReason,
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Sebep Ekle'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: reasons.isEmpty
                        ? const Center(
                            child: Text('Henüz gider sebebi yok.'),
                          )
                        : ListView.builder(
                            itemCount: reasons.length,
                            itemBuilder: (context, index) {
                              final reason = reasons[index];

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    reason['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _editReason(reason),
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'Düzenle',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteReason(reason),
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red,
                                        tooltip: 'Sil',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}

class _ExpensePaymentMethodSettingsDialog extends StatefulWidget {
  final Future<void> Function() onChanged;

  const _ExpensePaymentMethodSettingsDialog({
    required this.onChanged,
  });

  @override
  State<_ExpensePaymentMethodSettingsDialog> createState() =>
      _ExpensePaymentMethodSettingsDialogState();
}

class _ExpensePaymentMethodSettingsDialogState
    extends State<_ExpensePaymentMethodSettingsDialog> {
  bool isLoading = true;
  List<Map<String, dynamic>> methods = [];

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final data = await DatabaseService.instance.getExpensePaymentMethods();

    if (!mounted) return;

    setState(() {
      methods = data;
      isLoading = false;
    });
  }

  Future<String?> _showMethodNameDialog({
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          title: Text(
            initialValue == null
                ? 'Yeni Ödeme Yöntemi'
                : 'Ödeme Yöntemini Düzenle',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ödeme yöntemi adı',
              hintText: 'Örn: Havale',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _addMethod() async {
    final name = await _showMethodNameDialog();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await DatabaseService.instance.addExpensePaymentMethod(name);
    await _loadMethods();
    await widget.onChanged();
  }

  Future<void> _editMethod(Map<String, dynamic> method) async {
    final methodId = _toNullableInt(method['id']);

    if (methodId == null) {
      return;
    }

    final name = await _showMethodNameDialog(
      initialValue: method['name'].toString(),
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    await DatabaseService.instance.updateExpensePaymentMethod(
      methodId: methodId,
      name: name,
    );

    await _loadMethods();
    await widget.onChanged();
  }

  Future<void> _deleteMethod(Map<String, dynamic> method) async {
    final methodId = _toNullableInt(method['id']);

    if (methodId == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          title: const Text('Ödeme yöntemi silinsin mi?'),
          content: Text(
            '"${method['name']}" artık yeni gider girişlerinde görünmeyecek. Eski gider kayıtları korunacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await DatabaseService.instance.deactivateExpensePaymentMethod(methodId);
    await _loadMethods();
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceLight,
      title: const Text('Gider Ödeme Yöntemleri'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addMethod,
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Ödeme Yöntemi Ekle'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: methods.isEmpty
                        ? const Center(
                            child: Text('Henüz ödeme yöntemi yok.'),
                          )
                        : ListView.builder(
                            itemCount: methods.length,
                            itemBuilder: (context, index) {
                              final method = methods[index];

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    method['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _editMethod(method),
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'Düzenle',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteMethod(method),
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red,
                                        tooltip: 'Sil',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}

class _CashReportPage extends StatefulWidget {
  const _CashReportPage();

  @override
  State<_CashReportPage> createState() => _CashReportPageState();
}

class _CashReportPageState extends State<_CashReportPage> {
  bool isLoading = true;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  List<_ReportDateColumn> dateColumns = [];
  List<_CashReportRow> incomeRows = [];
  List<_CashReportRow> expenseRows = [];
  List<_CashReportRow> summaryRows = [];

  double totalIncome = 0;
  double totalExpense = 0;
  double netCash = 0;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day);

    _loadReport();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  List<_ReportDateColumn> _buildDateColumns({
    required DateTime start,
    required DateTime end,
  }) {
    final columns = <_ReportDateColumn>[];
    var current = _dateOnly(start);
    final last = _dateOnly(end);

    while (!current.isAfter(last)) {
      columns.add(
        _ReportDateColumn(
          key: _dateKey(current),
          label: _formatDateShort(current),
        ),
      );

      current = current.add(const Duration(days: 1));
    }

    return columns;
  }

  String _incomeMethodLabel(dynamic value) {
    final raw = value?.toString() ?? '';

    switch (raw) {
      case 'cash':
      case 'Nakit':
      case 'nakit':
        return 'Nakit';

      case 'credit_card':
      case 'card':
      case 'Kredi Kartı':
      case 'kredi_karti':
        return 'Kredi Kartı';

      default:
        return raw.isEmpty ? 'Belirtilmedi' : raw;
    }
  }

  _CashReportRow _emptyRow(String label) {
    return _CashReportRow(
      label: label,
      valuesByDay: {
        for (final column in dateColumns) column.key: 0.0,
      },
    );
  }

  double _rowTotal(_CashReportRow row) {
    return row.valuesByDay.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
  }

  Future<void> _loadReport() async {
    setState(() {
      isLoading = true;
    });

    await DatabaseService.instance.ensureCashRegisterSchema();

    final start = _dateOnly(startDate);
    final endInclusive = _dateOnly(endDate);
    final queryEnd = endInclusive.add(const Duration(days: 1));

    final columns = _buildDateColumns(
      start: start,
      end: endInclusive,
    );

    final incomeData = await DatabaseService.instance.getCashIncomeByDayBetween(
      start: start,
      end: queryEnd,
    );

    final expenseData =
        await DatabaseService.instance.getExpenseSummaryByReasonAndDayBetween(
      start: start,
      end: queryEnd,
    );

    if (!mounted) return;

    dateColumns = columns;

    final cashIncomeRow = _emptyRow('Nakit');
    final cardIncomeRow = _emptyRow('Kredi Kartı');
    final totalIncomeRow = _emptyRow('Toplam Gelir');

    for (final row in incomeData) {
      final day = row['day']?.toString();
      if (day == null) continue;

      final methodLabel = _incomeMethodLabel(row['payment_method']);
      final amount = _toDouble(row['total_amount']);

      if (methodLabel == 'Nakit') {
        cashIncomeRow.valuesByDay[day] =
            (cashIncomeRow.valuesByDay[day] ?? 0) + amount;
      } else if (methodLabel == 'Kredi Kartı') {
        cardIncomeRow.valuesByDay[day] =
            (cardIncomeRow.valuesByDay[day] ?? 0) + amount;
      }

      totalIncomeRow.valuesByDay[day] =
          (totalIncomeRow.valuesByDay[day] ?? 0) + amount;
    }

    final expenseRowMap = <String, _CashReportRow>{};

    for (final row in expenseData) {
      final reasonName = row['reason_name']?.toString() ?? 'Belirtilmedi';
      final paymentMethod =
          row['payment_method_name']?.toString() ?? 'Belirtilmedi';
      final day = row['day']?.toString();

      if (day == null) continue;

      final amount = _toDouble(row['total_amount']);
      final rowLabel = '$reasonName / $paymentMethod';

      expenseRowMap.putIfAbsent(
        rowLabel,
        () => _emptyRow(rowLabel),
      );

      expenseRowMap[rowLabel]!.valuesByDay[day] =
          (expenseRowMap[rowLabel]!.valuesByDay[day] ?? 0) + amount;
    }

    final totalExpenseRow = _emptyRow('Toplam Gider');

    for (final row in expenseRowMap.values) {
      for (final column in dateColumns) {
        totalExpenseRow.valuesByDay[column.key] =
            (totalExpenseRow.valuesByDay[column.key] ?? 0) +
                (row.valuesByDay[column.key] ?? 0);
      }
    }

    final netCashRow = _emptyRow('Net Kasa');

    for (final column in dateColumns) {
      final income = totalIncomeRow.valuesByDay[column.key] ?? 0;
      final expense = totalExpenseRow.valuesByDay[column.key] ?? 0;

      netCashRow.valuesByDay[column.key] = income - expense;
    }

    setState(() {
      incomeRows = [
        cashIncomeRow,
        cardIncomeRow,
        totalIncomeRow.copyWith(isTotal: true),
      ];

      expenseRows = [
        ...expenseRowMap.values,
        totalExpenseRow.copyWith(isTotal: true),
      ];

      summaryRows = [
        totalIncomeRow.copyWith(label: 'Toplam Gelir', isTotal: true),
        totalExpenseRow.copyWith(label: 'Toplam Gider', isTotal: true),
        netCashRow.copyWith(label: 'Net Kasa', isTotal: true),
      ];

      totalIncome = _rowTotal(totalIncomeRow);
      totalExpense = _rowTotal(totalExpenseRow);
      netCash = totalIncome - totalExpense;

      isLoading = false;
    });
  }

  Future<void> _pickSingleDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      startDate = _dateOnly(picked);
      endDate = _dateOnly(picked);
    });

    await _loadReport();
  }

  Future<void> _pickDateRange() async {
  final now = DateTime.now();

  final pickedStart = await showDatePicker(
    context: context,
    initialDate: startDate,
    firstDate: DateTime(2020),
    lastDate: now,
    helpText: 'Başlangıç Tarihini Seç',
    cancelText: 'İptal',
    confirmText: 'Seç',
  );

  if (pickedStart == null) {
    return;
  }

  if (!mounted) return;

  final safeInitialEndDate = endDate.isBefore(pickedStart)
      ? pickedStart
      : endDate;

  final pickedEnd = await showDatePicker(
    context: context,
    initialDate: safeInitialEndDate,
    firstDate: pickedStart,
    lastDate: now,
    helpText: 'Bitiş Tarihini Seç',
    cancelText: 'İptal',
    confirmText: 'Seç',
  );

  if (pickedEnd == null) {
    return;
  }

  setState(() {
    startDate = _dateOnly(pickedStart);
    endDate = _dateOnly(pickedEnd);
  });

  await _loadReport();
}

  String _selectedRangeText() {
    if (_dateKey(startDate) == _dateKey(endDate)) {
      return _formatDateOnly(startDate);
    }

    return '${_formatDateOnly(startDate)} - ${_formatDateOnly(endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasTotalColumn = dateColumns.length > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kasa Raporu',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: isNarrow ? 24 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seçilen tarih aralığı için gelir, gider ve net kasa durumunu gösterir.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: isNarrow ? 14 : 16,
                ),
              ),
              const SizedBox(height: 24),

              _CashReportFilterCard(
                selectedRangeText: _selectedRangeText(),
                onPickSingleDate: _pickSingleDate,
                onPickDateRange: _pickDateRange,
                onRefresh: _loadReport,
              ),

              const SizedBox(height: 24),

              _CashSummaryCards(
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                netCash: netCash,
              ),

              const SizedBox(height: 24),

              _CashReportTableCard(
                title: 'Gelirler',
                icon: Icons.trending_up,
                leadingColumnTitle: 'Kasa Geliri',
                rows: incomeRows,
                dateColumns: dateColumns,
                hasTotalColumn: hasTotalColumn,
                positiveValues: true,
              ),

              const SizedBox(height: 24),

              _CashReportTableCard(
                title: 'Giderler',
                icon: Icons.trending_down,
                leadingColumnTitle: 'Gider Sebebi / Ödeme Yöntemi',
                rows: expenseRows,
                dateColumns: dateColumns,
                hasTotalColumn: hasTotalColumn,
                positiveValues: false,
              ),

              const SizedBox(height: 24),

              _CashReportTableCard(
                title: 'Kasa Özeti',
                icon: Icons.account_balance_wallet,
                leadingColumnTitle: 'Özet',
                rows: summaryRows,
                dateColumns: dateColumns,
                hasTotalColumn: hasTotalColumn,
                positiveValues: true,
                highlightNetRow: true,
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: netCash >= 0
                      ? AppTheme.pastelGreen.withOpacity(0.18)
                      : Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: netCash >= 0
                        ? AppTheme.pastelGreen.withOpacity(0.6)
                        : Colors.red.withOpacity(0.35),
                  ),
                ),
                child: Text(
                  'Toplam Gelir ${_formatMoney(totalIncome)} - Toplam Gider ${_formatMoney(totalExpense)} = Net Kasa ${_formatMoney(netCash)}',
                  style: TextStyle(
                    color: netCash >= 0 ? AppTheme.textDark : Colors.red,
                    fontSize: isNarrow ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportDateColumn {
  final String key;
  final String label;

  const _ReportDateColumn({
    required this.key,
    required this.label,
  });
}

class _CashReportRow {
  final String label;
  final Map<String, double> valuesByDay;
  final bool isTotal;

  const _CashReportRow({
    required this.label,
    required this.valuesByDay,
    this.isTotal = false,
  });

  _CashReportRow copyWith({
    String? label,
    bool? isTotal,
  }) {
    return _CashReportRow(
      label: label ?? this.label,
      valuesByDay: Map<String, double>.from(valuesByDay),
      isTotal: isTotal ?? this.isTotal,
    );
  }
}

class _CashReportFilterCard extends StatelessWidget {
  final String selectedRangeText;
  final VoidCallback onPickSingleDate;
  final VoidCallback onPickDateRange;
  final VoidCallback onRefresh;

  const _CashReportFilterCard({
    required this.selectedRangeText,
    required this.onPickSingleDate,
    required this.onPickDateRange,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.12),
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.textMuted.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range, color: AppTheme.primary),
                const SizedBox(width: 10),
                Text(
                  selectedRangeText,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPickSingleDate,
            icon: const Icon(Icons.today),
            label: const Text('Tek Gün Seç'),
          ),
          OutlinedButton.icon(
            onPressed: onPickDateRange,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Tarih Aralığı Seç'),
          ),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
}

class _CashSummaryCards extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double netCash;

  const _CashSummaryCards({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCash,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;

        final cards = [
          _CashSummaryCard(
            title: 'Toplam Gelir',
            value: _formatMoney(totalIncome),
            icon: Icons.add_circle_outline,
            valueColor: AppTheme.pastelGreen,
          ),
          _CashSummaryCard(
            title: 'Toplam Gider',
            value: _formatMoney(totalExpense),
            icon: Icons.remove_circle_outline,
            valueColor: Colors.red,
          ),
          _CashSummaryCard(
            title: 'Net Kasa',
            value: _formatMoney(netCash),
            icon: Icons.account_balance_wallet,
            valueColor: netCash >= 0 ? AppTheme.primary : Colors.red,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _CashSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _CashSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textMuted.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: valueColor, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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

class _CashReportTableCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String leadingColumnTitle;
  final List<_CashReportRow> rows;
  final List<_ReportDateColumn> dateColumns;
  final bool hasTotalColumn;
  final bool positiveValues;
  final bool highlightNetRow;

  const _CashReportTableCard({
    required this.title,
    required this.icon,
    required this.leadingColumnTitle,
    required this.rows,
    required this.dateColumns,
    required this.hasTotalColumn,
    required this.positiveValues,
    this.highlightNetRow = false,
  });

  double _rowTotal(_CashReportRow row) {
    return row.valuesByDay.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
  }

  Color _valueColor(_CashReportRow row, double value) {
    if (highlightNetRow && row.label == 'Net Kasa') {
      return value >= 0 ? AppTheme.primary : Colors.red;
    }

    if (row.label.contains('Gider')) {
      return Colors.red;
    }

    if (row.isTotal) {
      return AppTheme.textDark;
    }

    return positiveValues ? AppTheme.textDark : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.textMuted.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textMuted.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                AppTheme.background,
              ),
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 230,
                    child: Text(
                      leadingColumnTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ...dateColumns.map(
                  (column) => DataColumn(
                    numeric: true,
                    label: Text(
                      column.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (hasTotalColumn)
                  const DataColumn(
                    numeric: true,
                    label: Text(
                      'Toplam',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
              rows: rows.map((row) {
                return DataRow(
                  color: row.isTotal
                      ? MaterialStateProperty.all(
                          AppTheme.background.withOpacity(0.75),
                        )
                      : null,
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 230,
                        child: Text(
                          row.label,
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontWeight:
                                row.isTotal ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ...dateColumns.map((column) {
                      final value = row.valuesByDay[column.key] ?? 0;

                      return DataCell(
                        Text(
                          _formatMoney(value),
                          style: TextStyle(
                            color: _valueColor(row, value),
                            fontWeight:
                                row.isTotal ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                    if (hasTotalColumn)
                      DataCell(
                        Text(
                          _formatMoney(_rowTotal(row)),
                          style: TextStyle(
                            color: _valueColor(row, _rowTotal(row)),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateShort(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day.$month';
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString()) ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

String _formatMoney(double value) {
  return '${value.toStringAsFixed(2)} ₺';
}

String _formatDateOnly(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day.$month.$year';
}

String _formatDateTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');

  if (date == null) {
    return '-';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day.$month.$year $hour:$minute';
}