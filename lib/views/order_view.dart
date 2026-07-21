import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../theme/theme.dart';
import '../models/product.dart';
import '../models/order_item.dart';
import 'payment_view.dart';

class OrderView extends StatelessWidget {
  final RestaurantController controller;
  final int tableId;

  const OrderView({Key? key, required this.controller, required this.tableId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final table = controller.tables.firstWhere((t) => t.id == tableId);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Sipariş Ekranı - ${table.name}', style: const TextStyle(color: AppTheme.textDark)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final table = controller.tables.firstWhere((t) => t.id == tableId);

          if (controller.isLoadingMenu) {
            return const Center(child: CircularProgressIndicator());
          }

          return Row(
            children: [
              // SOL TARAF - KATEGORİLER VE ÜRÜNLER (Ekranın 3/5'ini kaplar)
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    // 1. Kategori Listesi
                    Container(
                      width: 140, // Kategoriler için genişlik
                      color: Colors.white,
                      child: ListView.builder(
                        itemCount: controller.categories.length,
                        itemBuilder: (context, index) {
                          final category = controller.categories[index];
                          final isSelected = controller.selectedCategory == category;

                          return InkWell(
                            onTap: () => controller.changeCategory(category),
                            child: Container(
                              color: isSelected ? AppTheme.pastelGreen.withOpacity(0.3) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.green[800] : AppTheme.textDark,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    Container(width: 1, color: Colors.grey.withOpacity(0.2)),
                    
                    // 2. Filtrelenmiş Ürünler
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // Ürün kutusu sayısı
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: controller.filteredMenu.length,
                          itemBuilder: (context, index) {
                            final product = controller.filteredMenu[index];
                            return InkWell(
                              onTap: () => controller.addProductToTable(tableId, product),
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: AppTheme.pastelBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${product.price.toStringAsFixed(2)} ₺',
                                        style: TextStyle(fontSize: 15, color: AppTheme.textDark.withOpacity(0.8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SAĞ TARAF - ADİSYON (SİPARİŞ ÖZETİ) (Ekranın 2/5'ini kaplar)
              Container(width: 1, color: Colors.grey.withOpacity(0.2)),
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Adisyon', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: table.orders.isEmpty
                            ? const Center(child: Text('Henüz sipariş girilmedi.'))
                            : ListView.builder(
                                itemCount: table.orders.length,
                                itemBuilder: (context, index) {
                                  final orderItem = table.orders[index];
                                  return InkWell(
                                    onTap: () => _showNumpadDialog(context, controller, tableId, orderItem),
                                    child: ListTile(
                                      title: Text(orderItem.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('${orderItem.product.price} ₺ x ${_formatQuantity(orderItem.quantity)}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (controller.currentUser?.role.name == 'admin') ...[
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.pastelRed),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text('Ürünü Sil'),
                                                      content: Text('${orderItem.product.name} siparişten tamamen silinecek. Emin misiniz?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            controller.removeProductFromTable(tableId, orderItem.id);
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: const Text('Evet, Sil', style: TextStyle(color: AppTheme.pastelRed, fontWeight: FontWeight.bold)),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: AppTheme.pastelBlue),
                                              tooltip: 'Özel Fiyat Belirle',
                                              onPressed: () => _showCustomPriceDialog(context, controller, tableId, orderItem.product, table.customPrices[orderItem.product.id]),
                                            ),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.pastelGreen.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _formatQuantity(orderItem.quantity),
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Toplam:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text(
                                  '${table.currentTotal.toStringAsFixed(2)} ₺',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade200,
                                        foregroundColor: AppTheme.textDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: table.orders.isEmpty
                                          ? null
                                          : () {
                                              controller.printReceipt(tableId, PrintTarget.kitchen);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Mutfak Adisyonu Yazdırıldı.')),
                                              );
                                            },
                                      child: const Text('Mutfak Yazdır', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade200, 
                                        foregroundColor: AppTheme.textDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: table.orders.isEmpty
                                          ? null
                                          : () {
                                              controller.printReceipt(tableId, PrintTarget.cashier);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Kasa Adisyonu Yazdırıldı.')),
                                              );
                                            },
                                      child: const Text('Kasa Yazdır', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.pastelBlue,
                                        foregroundColor: AppTheme.textDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: table.orders.isEmpty
                                          ? null
                                          : () {
                                              _showMoveTableDialog(context, controller, table);
                                            },
                                      child: const Text('Masayı Taşı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                                if (controller.currentUser?.role.name == 'admin') ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.pastelYellow,
                                          foregroundColor: AppTheme.textDark,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: table.orders.isEmpty
                                          ? null
                                          : () async {
                                              final paymentCompleted = await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => PaymentView(
                                                    controller: controller,
                                                    tableId: tableId,
                                                  ),
                                                ),
                                              );

                                              if (paymentCompleted == true && context.mounted) {
                                                Navigator.pop(context);
                                              }
                                            },
                                        child: const Text('Ödeme Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      )
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

  void _showMoveTableDialog(BuildContext context, RestaurantController controller, TableModel currentTable) {
    final emptyTables = controller.tables.where((t) => t.status == TableStatus.empty).toList();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Masa Taşı', style: TextStyle(color: AppTheme.textDark)),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: emptyTables.length,
              itemBuilder: (context, index) {
                final target = emptyTables[index];
                return ListTile(
                  title: Text(target.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.table_restaurant, color: AppTheme.pastelBlue),
                  onTap: () {
                    controller.moveTable(currentTable.id, target.id);
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close order view
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${currentTable.name}, ${target.name} masasına taşındı.'),
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

  void _showNumpadDialog(BuildContext context, RestaurantController controller, int tableId, OrderItem orderItem) {
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    onPressed: () => onKeyPress(text),
                    child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppTheme.surfaceLight,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(orderItem.product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
                      ),
                      child: Text(
                        inputValue.isEmpty ? '0' : inputValue,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [buildBtn('7'), buildBtn('8'), buildBtn('9')]),
                    Row(children: [buildBtn('4'), buildBtn('5'), buildBtn('6')]),
                    Row(children: [buildBtn('1'), buildBtn('2'), buildBtn('3')]),
                    Row(children: [buildBtn('C', color: AppTheme.pastelRed), buildBtn('0'), buildBtn('.')]),
                    Row(children: [buildBtn('DEL', color: AppTheme.pastelRed)]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.textMuted.withOpacity(0.2),
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pastelGreen,
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final newQ = double.tryParse(inputValue) ?? 0.0;
                              controller.setProductQuantity(tableId, orderItem.id, newQ);
                              Navigator.pop(context);
                            },
                            child: const Text('Onayla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _showCustomPriceDialog(BuildContext context, RestaurantController controller, int tableId, Product product, double? currentCustomPrice) {
    String inputValue = currentCustomPrice != null ? currentCustomPrice.toStringAsFixed(2).replaceAll('.00', '') : product.price.toStringAsFixed(2).replaceAll('.00', '');

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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    onPressed: () => onKeyPress(text),
                    child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppTheme.surfaceLight,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${product.name} Özel Fiyat', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
                      ),
                      child: Text(
                        inputValue.isEmpty ? '0 ₺' : '$inputValue ₺',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(children: [buildBtn('7'), buildBtn('8'), buildBtn('9')]),
                    Row(children: [buildBtn('4'), buildBtn('5'), buildBtn('6')]),
                    Row(children: [buildBtn('1'), buildBtn('2'), buildBtn('3')]),
                    Row(children: [buildBtn('C', color: AppTheme.pastelRed), buildBtn('0'), buildBtn('.')]),
                    Row(children: [buildBtn('DEL', color: AppTheme.pastelRed)]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.textMuted.withOpacity(0.2),
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pastelGreen,
                              foregroundColor: AppTheme.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final newP = double.tryParse(inputValue) ?? product.price;
                              controller.setCustomPrice(tableId, product.id, newP);
                              Navigator.pop(context);
                            },
                            child: const Text('Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}