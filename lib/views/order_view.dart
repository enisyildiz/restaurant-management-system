import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../theme/theme.dart';
import '../models/product.dart';
import '../models/order_item.dart';
import 'payment_view.dart';
import '../utils/money_formatter.dart';

class OrderView extends StatefulWidget {
  final RestaurantController controller;
  final int tableId;

  const OrderView({Key? key, required this.controller, required this.tableId})
      : super(key: key);

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  static const bool _allowExitWithoutPrinterForTesting = true;   // When Test over change to False

  String _numpadValue = '0';

  final Set<String> _selectedOrderItemIds = {};
  final Set<String> _orderItemIdsAddedInThisView = {};

  bool _isCashierPrinting = false;

  @override
Widget build(BuildContext context) {
  final initialTable =
      widget.controller.tables.firstWhere((t) => t.id == widget.tableId);

  return WillPopScope(
    onWillPop: () async {
      final currentTable = widget.controller.tables.firstWhere(
        (t) => t.id == widget.tableId,
        orElse: () => initialTable,
      );

      await _closeAdisyon(currentTable);

      return false;
    },
    child: Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Sipariş Ekranı - ${initialTable.name}',
          style: const TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final table =
              widget.controller.tables.firstWhere((t) => t.id == widget.tableId);

          if (widget.controller.isLoadingMenu) {
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 950;

              if (isNarrow) {
                final adisyonHeight =
                    (constraints.maxHeight * 0.44).clamp(320.0, 500.0).toDouble();

                return Column(
                  children: [
                    SizedBox(
                      height: adisyonHeight,
                      child: _buildAdisyonPanel(table),
                    ),
                    Container(height: 1, color: Colors.grey.withOpacity(0.2)),
                    Expanded(
                      child: _buildMenuPanel(table),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  // SOL TARAF - ADİSYON
                  Expanded(
                    flex: 2,
                    child: _buildAdisyonPanel(table),
                  ),

                  Container(width: 1, color: Colors.grey.withOpacity(0.2)),

                  // SAĞ TARAF - KATEGORİLER / ÜRÜNLER / NUMPAD
                  Expanded(
                    flex: 3,
                    child: _buildMenuPanel(table),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

Widget _buildMenuPanel(TableModel table) {
  return Container(
    color: AppTheme.background,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;

        final categoryWidth = isCompact ? 118.0 : 135.0;
        final controlsHeight =
            (constraints.maxHeight * 0.43).clamp(400.0, 455.0).toDouble();

        final productCardMaxWidth = isCompact ? 150.0 : 165.0;

        return Row(
          children: [
            _buildCategoryList(categoryWidth),

            Container(width: 1, color: Colors.grey.withOpacity(0.2)),

            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        itemCount: widget.controller.filteredMenu.length,
                        gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: productCardMaxWidth,
                          mainAxisExtent: 65,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          final product =
                              widget.controller.filteredMenu[index];
                          return _buildProductCard(product);
                        },
                      ),
                    ),
                  ),

                  Container(height: 1, color: Colors.grey.withOpacity(0.2)),

                  SizedBox(
                    height: controlsHeight,
                    child: _buildMenuBottomControls(table),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildMenuBottomControls(TableModel table) {
  return Container(
    color: Colors.white,
    padding: const EdgeInsets.all(10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final numpadWidth = isCompact ? 300.0 : 380.0;

        return Row(
          children: [
            SizedBox(
              width: numpadWidth,
              child: _buildCompactNumpad(),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildActionButtonStrip(table),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildActionButtonStrip(TableModel table) {
  final canRemoveSelected = _selectedOrderItemIds.any(
    (id) => _canSelectOrderItem(
      table: table,
      orderItemId: id,
    ),
  );

  return Column(
    children: [
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: _buildOrderActionButton(
                text: _isCashierPrinting ? 'Yazdırılıyor...' : 'Kasa Yazdır',
                color: Colors.green.shade200,
                onPressed: table.orders.isEmpty || _isCashierPrinting
                    ? null
                    : () async {
                        setState(() {
                          _isCashierPrinting = true;
                        });

                        final printed = await widget.controller.printReceipt(
                          widget.tableId,
                          PrintTarget.cashier,
                        );

                        if (printed || _allowExitWithoutPrinterForTesting) {
                          widget.controller.markTableAskedForCheck(widget.tableId);
                        }

                        await Future.delayed(const Duration(seconds: 5));

                        if (!mounted) return;

                        setState(() {
                          _isCashierPrinting = false;
                        });
                      },
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrderActionButton(
                text: 'Masayı Taşı',
                color: AppTheme.pastelBlue,
                onPressed: table.orders.isEmpty
                    ? null
                    : () {
                        if (table.status == TableStatus.askedForCheck) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Masa kilitli! Taşımak için kilidi kaldırın.'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(
                                bottom: MediaQuery.of(context).size.height - 120,
                                left: 20,
                                right: 20,
                              ),
                            ),
                          );
                          return;
                        }
                        _showMoveTableDialog(
                          context,
                          widget.controller,
                          table,
                        );
                      },
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: _buildOrderActionButton(
                text: 'Adisyondan Kaldır',
                color: AppTheme.pastelRed,
                onPressed: canRemoveSelected
                    ? () async {
                        await _removeSelectedOrderItems(table);
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrderActionButton(
                text: 'Kilidi Kaldır',
                color: (table.status == TableStatus.askedForCheck &&
                        widget.controller.currentUser?.role.name == 'admin')
                    ? Colors.orange.shade300
                    : Colors.grey.shade300,
                onPressed: (table.status == TableStatus.askedForCheck &&
                        widget.controller.currentUser?.role.name == 'admin')
                    ? () {
                        widget.controller.unlockTable(table.id);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildOrderActionButton({
  required String text,
  required Color color,
  required VoidCallback? onPressed,
}) {
  return SizedBox.expand(
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppTheme.textDark,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: AppTheme.textMuted,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

Widget _buildCategoryList(double width) {
  return Container(
    width: width,
    color: Colors.white,
    child: ListView.builder(
      itemCount: widget.controller.categories.length,
      itemBuilder: (context, index) {
        final category = widget.controller.categories[index];
        final isSelected = widget.controller.selectedCategory == category;

        return InkWell(
          onTap: () => widget.controller.changeCategory(category),
          child: Container(
            color: isSelected
                ? AppTheme.pastelGreen.withOpacity(0.3)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 12,
            ),
            child: Text(
              category,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.green[800] : AppTheme.textDark,
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildProductCard(Product product) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _addProductToTable(product),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: AppTheme.pastelBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textMuted.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 15.5,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _addProductToTable(Product product) {
  final table = widget.controller.tables.firstWhere((t) => t.id == widget.tableId);
  if (table.status == TableStatus.askedForCheck) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Masa kilitli! Ürün eklemek için kilidi kaldırın.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 20,
          right: 20,
        ),
      ),
    );
    return;
  }

  final beforeIds = widget.controller
      .ordersForTable(widget.tableId)
      .map((item) => item.id)
      .toSet();

  final qty = double.tryParse(_numpadValue.replaceAll(',', '.')) ?? 0.0;

  if (qty > 0) {
    widget.controller.addProductToTable(
      widget.tableId,
      product,
      quantity: qty,
    );
  } else {
    widget.controller.addProductToTable(widget.tableId, product);
  }

  final afterItems = widget.controller.ordersForTable(widget.tableId);

  final newIds = afterItems
      .where((item) => !beforeIds.contains(item.id))
      .map((item) => item.id);

  setState(() {
    _numpadValue = '0';
    _orderItemIdsAddedInThisView.addAll(newIds);
  });
}

Widget _buildAdisyonPanel(TableModel table) {
  return Container(
    color: Colors.white,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Adisyon',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: table.orderGroups.isEmpty
              ? const Center(child: Text('Henüz sipariş girilmedi.'))
              : ListView.builder(
                  itemCount: table.orderGroups.length,
                  itemBuilder: (context, groupIndex) {
                    final group = table.orderGroups[groupIndex];

                    if (group.items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final timeStr =
                        '${group.createdAt.hour.toString().padLeft(2, '0')}:${group.createdAt.minute.toString().padLeft(2, '0')}';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Sipariş Saati: $timeStr',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: group.items.length,
                          itemBuilder: (context, index) {
                            final orderItem = group.items[index];
                            final effectivePrice =
                                table.customPrices[orderItem.product.id] ??
                                    orderItem.product.price;

                            final canSelect = _canSelectOrderItem(
  table: table,
  orderItemId: orderItem.id,
);

final isSelected = _selectedOrderItemIds.contains(orderItem.id);

                              return InkWell(
                                onTap: canSelect
                                    ? () {
                                        _toggleOrderItemSelection(
                                          table: table,
                                          orderItemId: orderItem.id,
                                        );
                                      }
                                    : null,
                                child: Container(
                                  color: isSelected
                                      ? AppTheme.pastelYellow.withOpacity(0.35)
                                      : Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    leading: canSelect
                                        ? Checkbox(
                                            value: isSelected,
                                            onChanged: (_) {
                                              _toggleOrderItemSelection(
                                                table: table,
                                                orderItemId: orderItem.id,
                                              );
                                            },
                                          )
                                        : const Icon(
                                            Icons.lock_outline,
                                            size: 20,
                                            color: AppTheme.textMuted,
                                          ),
                                    title: Text(
                                      orderItem.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${MoneyFormatter.formatTl(effectivePrice)} x ${_formatQuantity(orderItem.quantity)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isAdminUser()) ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: AppTheme.pastelBlue,
                                            ),
                                            tooltip: 'Özel Fiyat Belirle',
                                            onPressed: () {
                                              final price = MoneyFormatter.tryParseAmount(_numpadValue) ?? 0.0;

                                              if (price > 0) {
                                                widget.controller.setCustomPrice(
                                                  widget.tableId,
                                                  orderItem.product.id,
                                                  price,
                                                );

                                                setState(() {
                                                  _numpadValue = '0';
                                                });
                                              } else {
                                                _showCustomPriceDialog(
                                                  context,
                                                  widget.controller,
                                                  widget.tableId,
                                                  orderItem.product,
                                                  table.customPrices[orderItem.product.id],
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.pastelGreen.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _formatQuantity(orderItem.quantity),
                                            style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                          },
                        ),
                      ],
                    );
                  },
                ),
        ),

        _buildAdisyonBottomButtons(table),
      ],
    ),
  );
}

Widget _buildAdisyonBottomButtons(TableModel table) {
  final openedAt = table.seatedAt;
  final lastOrderAt = _getLastOrderTime(table);
  final canTakePayment = _isAdminUser();

  return Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    decoration: BoxDecoration(
      color: AppTheme.background,
      border: Border(
        top: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBillInfoLine(
          label: 'Adisyon Açılış:',
          value: '${_formatShortTime(openedAt)} (${_formatElapsed(openedAt)})',
        ),
        _buildBillInfoLine(
          label: 'Son Sipariş:',
          value:
              '${_formatShortTime(lastOrderAt)} (${_formatElapsed(lastOrderAt)})',
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Toplam:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              MoneyFormatter.formatTl(table.currentTotal),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            if (widget.controller.currentUser?.role.name == 'admin') ...[
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pastelYellow,
                      foregroundColor: AppTheme.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: table.orders.isEmpty
                      ? null
                      : () async {
                          if (!canTakePayment) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ödeme alma işlemi sadece kasa/yönetici kullanıcısı tarafından yapılabilir.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final paymentCompleted =
                              await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentView(
                                controller: widget.controller,
                                tableId: widget.tableId,
                              ),
                            ),
                          );

                          if (paymentCompleted == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                    child: const Text(
                      'Ödeme Al',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade300,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await _closeAdisyon(table);
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Adisyonu\nKapat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await _closeAdisyon(table);
                    },
                    child: const Text(
                      'Adisyonu Kapat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
  Future<void> _closeAdisyon(TableModel table) async {
  final currentTable = widget.controller.tables.firstWhere(
    (t) => t.id == widget.tableId,
    orElse: () => table,
  );

  // If this screen did not add anything, closing must never print.
  if (_orderItemIdsAddedInThisView.isEmpty) {
    if (!mounted) return;

    setState(() {
      _selectedOrderItemIds.clear();
    });

    Navigator.pop(context);
    return;
  }

  final printed = await widget.controller.printReceipt(
    widget.tableId,
    PrintTarget.kitchen,
    onlyOrderItemIds: _orderItemIdsAddedInThisView,
  );

  if (!printed) {
    if (!_allowExitWithoutPrinterForTesting) {
      return;
    }

    final exitAnyway = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          title: const Text('Test Çıkışı'),
          content: const Text(
            'Mutfak yazıcısı bulunamadı.\n\n'
            'Test için adisyonu kapatıp bu yeni siparişleri kilitlemek ister misin?\n\n'
            'Not: Gerçek kullanımda bu seçenek kapatılmalı.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hayır'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.pastelRed,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Test İçin Kapat'),
            ),
          ],
        );
      },
    );

    if (exitAnyway != true) {
      return;
    }

    for (final group in currentTable.orderGroups) {
      final containsCurrentSessionItem = group.items.any(
        (item) => _orderItemIdsAddedInThisView.contains(item.id),
      );

      if (containsCurrentSessionItem) {
        group.isPrintedToKitchen = true;
      }
    }
  }

  widget.controller.finalizeKitchenOrderItems(
    widget.tableId,
    _orderItemIdsAddedInThisView.toList(),
  );

  if (!mounted) return;

  setState(() {
    _selectedOrderItemIds.clear();
    _orderItemIdsAddedInThisView.clear();
  });

  Navigator.pop(context);
}

  void _handleCompactNumpadKey(String key) {
  setState(() {
    if (key == 'C') {
      _numpadValue = '0';
      return;
    }

    if (key == '<') {
      if (_numpadValue.length <= 1 || _numpadValue == '0') {
        _numpadValue = '0';
      } else {
        _numpadValue = _numpadValue.substring(0, _numpadValue.length - 1);
      }
      return;
    }

    if (key == ',' || key == '.') {
      if (!_numpadValue.contains('.')) {
        _numpadValue = _numpadValue == '0' ? '0.' : '$_numpadValue.';
      }
      return;
    }

    if (_numpadValue == '0') {
      _numpadValue = key;
    } else {
      _numpadValue += key;
    }
  });
}

Widget _buildCompactNumpad() {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppTheme.textMuted.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.20),
                  ),
                ),
                child: Text(
                  _numpadValue,
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 58,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pastelRed,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleCompactNumpadKey('C'),
                child: const Text(
                  'C',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildCompactNumpadButton('1'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('2'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('3'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    _buildCompactNumpadButton('4'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('5'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('6'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    _buildCompactNumpadButton('7'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('8'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('9'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    _buildCompactNumpadButton('.'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('0'),
                    const SizedBox(width: 8),
                    _buildCompactNumpadButton('<', isBackspace: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildCompactNumpadButton(
  String key, {
  bool isBackspace = false,
}) {
  return Expanded(
    child: SizedBox.expand(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isBackspace ? Colors.orange.shade300 : Colors.grey.shade100,
          foregroundColor: AppTheme.textDark,
          padding: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _handleCompactNumpadKey(key),
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

  bool _isAdminUser() {
  final roleName = widget.controller.currentUser?.role.name;
  return roleName == 'admin' || roleName == 'superadmin';
}

bool _isWaiterUser() {
  return widget.controller.currentUser?.role.name == 'waiter';
}

bool _canSelectOrderItem({
  required TableModel table,
  required String orderItemId,
}) {
  if (_isAdminUser()) {
    return true;
  }

  if (!_isWaiterUser()) {
    return false;
  }

  for (final group in table.orderGroups) {
    final containsItem = group.items.any((item) => item.id == orderItemId);

    if (containsItem) {
      return !group.isPrintedToKitchen;
    }
  }

  return false;
}

void _toggleOrderItemSelection({
  required TableModel table,
  required String orderItemId,
}) {
  if (!_canSelectOrderItem(table: table, orderItemId: orderItemId)) {
    return;
  }

  setState(() {
    if (_selectedOrderItemIds.contains(orderItemId)) {
      _selectedOrderItemIds.remove(orderItemId);
    } else {
      _selectedOrderItemIds.add(orderItemId);
    }
  });
}

Future<void> _removeSelectedOrderItems(TableModel table) async {
  if (table.status == TableStatus.askedForCheck) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Masa kilitli! Ürün çıkarmak için kilidi kaldırın.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 20,
          right: 20,
        ),
      ),
    );
    return;
  }

  final removableIds = _selectedOrderItemIds
      .where(
        (id) => _canSelectOrderItem(
          table: table,
          orderItemId: id,
        ),
      )
      .toList();

  if (removableIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kaldırılabilecek ürün seçilmedi.'),
        backgroundColor: AppTheme.pastelRed,
      ),
    );
    return;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Seçili ürünler kaldırılsın mı?'),
        content: Text(
          '${removableIds.length} ürün adisyondan kaldırılacak.\n\n'
          'Garson kullanıcı sadece mutfağa gönderilmemiş ürünleri kaldırabilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.pastelRed,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Adisyondan Kaldır'),
          ),
        ],
      );
    },
  );

  if (confirm != true) {
    return;
  }

  for (final id in removableIds) {
    widget.controller.removeProductFromTable(
      widget.tableId,
      id,
    );
  }

  setState(() {
    _selectedOrderItemIds.clear();
  });
}

  void _showMoveTableDialog(BuildContext context,
      RestaurantController controller, TableModel currentTable) {
    final emptyTables =
        controller.tables.where((t) => t.status == TableStatus.empty).toList();
    if (emptyTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taşınabilecek boş masa bulunmuyor.'),
          backgroundColor: AppTheme.pastelRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Masa Taşı',
              style: TextStyle(color: AppTheme.textDark)),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: emptyTables.length,
              itemBuilder: (context, index) {
                final target = emptyTables[index];
                return ListTile(
                  title: Text(target.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.table_restaurant,
                      color: AppTheme.pastelBlue),
                  onTap: () {
                    controller.moveTable(currentTable.id, target.id);
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close order view
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${currentTable.name}, ${target.name} masasına taşındı.'),
                        backgroundColor: AppTheme.pastelGreen,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatQuantity(double q) {
    return q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
  }

  void _showNumpadDialog(BuildContext context, RestaurantController controller,
      int tableId, OrderItem orderItem) {
    String inputValue = _formatQuantity(orderItem.quantity);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void onKeyPress(String key) {
              setState(() {
                if (key == 'C') {
                  inputValue = '';
                } else if (key == 'DEL') {
                  if (inputValue.isNotEmpty) {
                    inputValue = inputValue.substring(0, inputValue.length - 1);
                  }
                } else if (key == '.') {
                  if (!inputValue.contains('.')) {
                    inputValue += inputValue.isEmpty ? '0.' : '.';
                  }
                } else {
                  inputValue += key;
                }
              });
            }

            Widget buildBtn(String text, {Color? color}) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color ?? AppTheme.surface,
                      foregroundColor: AppTheme.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    onPressed: () => onKeyPress(text),
                    child: Text(text,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppTheme.surfaceLight,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(orderItem.product.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.textMuted.withOpacity(0.2)),
                      ),
                      child: Text(
                        inputValue.isEmpty ? '0' : inputValue,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      buildBtn('7'),
                      buildBtn('8'),
                      buildBtn('9')
                    ]),
                    Row(children: [
                      buildBtn('4'),
                      buildBtn('5'),
                      buildBtn('6')
                    ]),
                    Row(children: [
                      buildBtn('1'),
                      buildBtn('2'),
                      buildBtn('3')
                    ]),
                    Row(children: [
                      buildBtn('C', color: AppTheme.pastelRed),
                      buildBtn('0'),
                      buildBtn('.')
                    ]),
                    Row(children: [buildBtn('DEL', color: AppTheme.pastelRed)]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.textMuted.withOpacity(0.2),
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pastelGreen,
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final newQ = double.tryParse(
                                    inputValue.replaceAll(',', '.'),
                                  ) ??
                                  0.0;

                              controller.setProductQuantity(
                                tableId,
                                orderItem.id,
                                newQ,
                              );

                              Navigator.pop(context);
                            },
                            child: const Text('Onayla',
                                style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
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
      },
    );
  }

  void _showCustomPriceDialog(
      BuildContext context,
      RestaurantController controller,
      int tableId,
      Product product,
      double? currentCustomPrice) {
    String inputValue = currentCustomPrice != null
        ? currentCustomPrice.toStringAsFixed(2).replaceAll('.00', '')
        : product.price.toStringAsFixed(2).replaceAll('.00', '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void onKeyPress(String key) {
              setState(() {
                if (key == 'C') {
                  inputValue = '';
                } else if (key == 'DEL') {
                  if (inputValue.isNotEmpty) {
                    inputValue = inputValue.substring(0, inputValue.length - 1);
                  }
                } else if (key == '.') {
                  if (!inputValue.contains('.')) {
                    inputValue += inputValue.isEmpty ? '0.' : '.';
                  }
                } else {
                  inputValue += key;
                }
              });
            }

            Widget buildBtn(String text, {Color? color}) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color ?? AppTheme.surface,
                      foregroundColor: AppTheme.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    onPressed: () => onKeyPress(text),
                    child: Text(text,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppTheme.surfaceLight,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${product.name} Özel Fiyat',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.textMuted.withOpacity(0.2)),
                      ),
                      child: Text(
                        inputValue.isEmpty ? '0 ₺' : '$inputValue ₺',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      buildBtn('7'),
                      buildBtn('8'),
                      buildBtn('9')
                    ]),
                    Row(children: [
                      buildBtn('4'),
                      buildBtn('5'),
                      buildBtn('6')
                    ]),
                    Row(children: [
                      buildBtn('1'),
                      buildBtn('2'),
                      buildBtn('3')
                    ]),
                    Row(children: [
                      buildBtn('C', color: AppTheme.pastelRed),
                      buildBtn('0'),
                      buildBtn('.')
                    ]),
                    Row(children: [buildBtn('DEL', color: AppTheme.pastelRed)]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.textMuted.withOpacity(0.2),
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pastelGreen,
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final newP =
                                  double.tryParse(inputValue) ?? product.price;
                              controller.setCustomPrice(
                                  tableId, product.id, newP);
                              Navigator.pop(context);
                            },
                            child: const Text('Kaydet',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
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
      },
    );
  }

  String _formatShortTime(DateTime? dt) {
  if (dt == null) return '--:--';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatElapsed(DateTime? dt) {
  if (dt == null) return '-';
  final diff = DateTime.now().difference(dt);

  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} dk';
  }

  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  if (minutes == 0) {
    return '$hours sa';
  }
  return '$hours sa $minutes dk';
}

DateTime? _getLastOrderTime(TableModel table) {
  final orders = table.orders;

  if (orders.isEmpty) {
    return table.seatedAt;
  }

  orders.sort(
    (a, b) => a.orderTime.compareTo(b.orderTime),
  );

  return orders.last.orderTime;
}

Widget _buildBillInfoLine({
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}
}
