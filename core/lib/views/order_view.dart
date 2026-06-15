import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../theme/theme.dart';

class OrderView extends StatelessWidget {
  final RestaurantController controller;
  final int tableId;

  const OrderView({Key? key, required this.controller, required this.tableId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Sipariş Ekranı - Masa $tableId', style: const TextStyle(color: AppTheme.textDark)),
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
                                  return ListTile(
                                    title: Text(orderItem.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('${orderItem.product.price} ₺ x ${orderItem.quantity}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.pastelRed),
                                          onPressed: () => controller.removeProductFromTable(tableId, orderItem.product),
                                        ),
                                        Text('${orderItem.quantity}', style: const TextStyle(fontSize: 18)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.pastelGreen),
                                          onPressed: () => controller.addProductToTable(tableId, orderItem.product),
                                        ),
                                      ],
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
                                  '${table.totalBill.toStringAsFixed(2)} ₺',
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
                                        backgroundColor: AppTheme.pastelRed,
                                        foregroundColor: AppTheme.textDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: table.orders.isEmpty
                                          ? null
                                          : () {
                                                  controller.checkoutTable(tableId);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Sipariş tamamlandı ve masa kapatıldı.')),
                                              );
                                            },
                                      child: const Text('Hesabı Kapat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
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
                                          : () {
                                              //controller.printReceipt(tableId, PrintTarget.cashier);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('No implementation')),
                                              );
                                            },
                                      child: const Text('Masayı Taşı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                        backgroundColor: AppTheme.pastelGreen,
                                        foregroundColor: AppTheme.textDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: table.orders.isEmpty
                                          ? null
                                          : () {
                                                  controller.saveTable(tableId);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Siparişler kayıt edildi.')),
                                              );
                                            },
                                      child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
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
                                          : () {
                                              //controller.printReceipt(tableId, PrintTarget.cashier);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('No implementation')),
                                              );
                                            },
                                      child: const Text('Ödeme Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                              controller.printReceipt(tableId, PrintTarget.kitchen);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Mutfak Adisyonu Yazdırıldı.')),
                                              );
                                            },
                                      child: const Text('Mutfak Adisyonu Yazdır', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                      child: const Text('Kasa Adisyonu Yazdır', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
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
}