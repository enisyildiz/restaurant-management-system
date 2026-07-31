import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:restaurant_management_app/services/database_service.dart';
import 'package:restaurant_management_app/models/table_model.dart';
import 'package:restaurant_management_app/models/product.dart';
import 'package:restaurant_management_app/models/order_group.dart';
import 'package:restaurant_management_app/models/order_item.dart';
import 'package:restaurant_management_app/models/payment_record.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    // In-memory testler için FFI başlat
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = FakePathProvider();
  });

  group('Database Integration: End-to-End Daily Report Simulation', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      
      final db = await dbService.database; 
      
      // Since DatabaseService is a singleton, deleting the file isn't enough,
      // it keeps the old connection in RAM. We must clear the tables.
      await db.execute('DELETE FROM receipts');
      await db.execute('DELETE FROM receipt_items');
    });

    test('Simulates 1 full day of restaurant operation and verifies Admin Reports', () async {
      final db = await dbService.database;
      
      // --- 1. SİMÜLASYON VERİSİ BASMA ---
      // 1 günlük (Örneğin dün) toplam 5 masa satışı simüle edeceğiz.
      // 3 nakit, 2 kart ödemesi olacak.
      
      final testDate = DateTime.now().subtract(const Duration(days: 1)); // Dünün tarihi
      final dateIso = testDate.toIso8601String();
      
      // 1. Masa: 150 TL Nakit
      await db.insert('receipts', {
        'table_id': 'm1', 'table_code': 'Masa 1', 'table_area': 'Bahçe', 'table_name': 'Masa 1',
        'total_amount': 150.0, 'total_paid': 150.0, 'cash_paid': 150.0, 'card_paid': 0.0, 'date_closed': dateIso,
      });
      
      // 2. Masa: 350 TL Kart
      await db.insert('receipts', {
        'table_id': 'm2', 'table_code': 'Masa 2', 'table_area': 'Salon', 'table_name': 'Masa 2',
        'total_amount': 350.0, 'total_paid': 350.0, 'cash_paid': 0.0, 'card_paid': 350.0, 'date_closed': dateIso,
      });
      
      // 3. Masa: 100 TL Parçalı (50 Nakit, 50 Kart) -> Toplamda Nakite ve Karta eklenecek
      await db.insert('receipts', {
        'table_id': 'm3', 'table_code': 'Masa 3', 'table_area': 'Teras', 'table_name': 'Masa 3',
        'total_amount': 100.0, 'total_paid': 100.0, 'cash_paid': 50.0, 'card_paid': 50.0, 'discount_amount': 0.0, 'date_closed': dateIso,
      });

      // 4. Masa: 200 TL Toplam Hesap, 50 TL İndirim (Discount), 150 TL Nakit Ödendi
      await db.insert('receipts', {
        'table_id': 'm4', 'table_code': 'Masa 4', 'table_area': 'Bahçe', 'table_name': 'Masa 4',
        'total_amount': 200.0, 'total_paid': 150.0, 'cash_paid': 150.0, 'card_paid': 0.0, 'discount_amount': 50.0, 'date_closed': dateIso,
      });
      
      // Beklenen Matematik:
      // Toplam Hesap (Total Amount) = 150 + 350 + 100 + 200 = 800 TL
      // Toplam İndirim (Discount) = 0 + 0 + 0 + 50 = 50 TL
      // Toplam Ödenen Ciro (Paid) = 150 + 350 + 100 + 150 = 750 TL
      // Toplam Nakit = 150 + 50 + 150 = 350 TL
      // Toplam Kart = 350 + 50 + 0 = 400 TL
      
      // --- 2. ADMIN PANEL RAPOR ÇEKİMİNİ TEST ETME ---
      final results = await db.rawQuery('SELECT SUM(total_amount) as total_amt, SUM(total_paid) as total_paid, SUM(discount_amount) as discount, SUM(cash_paid) as cash, SUM(card_paid) as card FROM receipts');
      
      final row = results.first;
      final totalAmt = (row['total_amt'] as num?)?.toDouble() ?? 0.0;
      final totalPaid = (row['total_paid'] as num?)?.toDouble() ?? 0.0;
      final totalDiscount = (row['discount'] as num?)?.toDouble() ?? 0.0;
      final totalCash = (row['cash'] as num?)?.toDouble() ?? 0.0;
      final totalCard = (row['card'] as num?)?.toDouble() ?? 0.0;

      // --- 3. ASSERTION (DOĞRULAMA) ---
      expect(totalAmt, 800.0, reason: 'İndirimsiz toplam hesap 800 TL olmalıdır.');
      expect(totalDiscount, 50.0, reason: 'Toplam indirim 50 TL olmalıdır.');
      expect(totalPaid, 750.0, reason: 'Kasa ciro (Toplam ödenen) 750 TL olmalıdır.');
      expect(totalCash, 350.0, reason: 'Toplam nakit 350 TL olmalıdır.');
      expect(totalCard, 400.0, reason: 'Toplam kart 400 TL olmalıdır.');
    });

    test('Active Session: Price updates applied to all historical orders of same product', () async {
      final db = await dbService.database;

      // 1. Yeni bir masa aç (Table Session)
      final sessionId = await dbService.createTableSession(
        tableId: 5,
        tableCode: 'Masa 5',
        tableArea: 'Salon',
        tableName: 'Masa 5',
        seatedAt: DateTime.now(),
      );

      // 2. Saat 12:00 -> 2 adet Çay söyle (Birim fiyatı: 10 TL)
      await dbService.insertOrderEvent(
        sessionId: sessionId,
        tableId: 5,
        tableCode: 'Masa 5',
        tableArea: 'Salon',
        tableName: 'Masa 5',
        eventType: 'order_added',
        createdAt: DateTime.now(),
        productId: 1,
        productName: 'Çay',
        productCategory: 'İçecek',
        quantityDelta: 2.0,
        unitPrice: 10.0,
        totalPrice: 20.0,
      );

      // 3. Saat 13:00 -> 1 adet daha Çay söyle (Birim fiyatı: 10 TL)
      await dbService.insertOrderEvent(
        sessionId: sessionId,
        tableId: 5,
        tableCode: 'Masa 5',
        tableArea: 'Salon',
        tableName: 'Masa 5',
        eventType: 'order_added',
        createdAt: DateTime.now(),
        productId: 1,
        productName: 'Çay',
        productCategory: 'İçecek',
        quantityDelta: 1.0,
        unitPrice: 10.0,
        totalPrice: 10.0,
      );

      // Şu an veritabanında 3 çay var, tanesi 10 TL'den Toplam: 30 TL olmalı.
      final beforeUpdate = await db.rawQuery('SELECT SUM(total_price) as total FROM order_events WHERE session_id = ?', [sessionId]);
      expect((beforeUpdate.first['total'] as num).toDouble(), 30.0);

      // 4. Admin fiyatı 15 TL yaptı ve updateOrderEventPriceForSessionProduct çağrıldı.
      // Bu fonksiyon açık masadaki tüm o ürünlerin fiyatını değiştirir.
      await dbService.updateOrderEventPriceForSessionProduct(
        sessionId: sessionId, 
        productId: 1, 
        newUnitPrice: 15.0
      );

      // 5. Doğrulama: Artık 3 çay * 15 TL = 45 TL olmalı.
      final afterUpdate = await db.rawQuery('SELECT SUM(total_price) as total FROM order_events WHERE session_id = ?', [sessionId]);
      expect((afterUpdate.first['total'] as num).toDouble(), 45.0, reason: 'Fiyat değiştiğinde geçmiş siparişlerin toplamı da güncellenmelidir.');
    });

    test('End-to-End: TableModel payment and discount flow via saveClosedTable', () async {
      final db = await dbService.database;
      
      // 1. Yeni bir masa oluştur ve veritabanında başlat
      final sessionId = await dbService.createTableSession(
        tableId: 10,
        tableCode: 'Masa 10',
        tableArea: 'Teras',
        tableName: 'Masa 10',
        seatedAt: DateTime.now(),
      );

      // 2. TableModel örneğini oluştur (Controller içinde olduğu gibi)
      final table = TableModel(
        id: 10,
        code: 'Masa 10',
        name: 'Masa 10',
        area: 'Teras',
        activeSessionId: sessionId,
      );

      final product = Product(id: 1, name: 'Tatlı', price: 100.0, category: 'Yiyecek');
      
      // Sipariş eklendi
      table.orderGroups = [
        OrderGroup(items: [
          OrderItem(product: product, quantity: 1, orderTime: DateTime.now()), // 100 TL
        ])
      ];

      // 3. Ödemeleri (Nakit ve İndirim) modele ekle
      table.payments.add(PaymentRecord(amount: 70.0, method: PaymentMethod.cash, paidAt: DateTime.now()));
      table.payments.add(PaymentRecord(amount: 30.0, method: PaymentMethod.discount, paidAt: DateTime.now()));

      // Modele göre doğrulama
      expect(table.remainingAmount, 0.0);
      expect(table.totalCashPaid, 70.0);
      expect(table.totalDiscount, 30.0);

      // 4. Veritabanına Masa Kapatma komutu gönder
      await dbService.saveClosedTable(table);

      // 5. Veritabanını raporlama gibi kontrol et (receipts tablosu)
      // receipts tablosunda session_id yoktur, table_id vardır.
      final results = await db.rawQuery('SELECT * FROM receipts WHERE table_id = ? ORDER BY id DESC LIMIT 1', [10]);
      
      expect(results.length, 1);
      final receipt = results.first;
      
      // Muhasebe kuralına göre receipts tablosundaki "total_amount" indirimsiz hesap değildir,
      // sadece nakit ve kartın toplamıdır. (İndirim tutarı ciroya yansımaz!)
      // Beklenen matematik (DatabaseService 385. satır):
      // netRevenueAmount = cashPaid + cardPaid = 70 + 0 = 70
      // total_amount = netRevenueAmount = 70
      
      expect((receipt['cash_paid'] as num).toDouble(), 70.0);
      expect((receipt['card_paid'] as num).toDouble(), 0.0);
      expect((receipt['discount_amount'] as num).toDouble(), 30.0);
      expect((receipt['total_paid'] as num).toDouble(), 70.0); // Gerçekleşen ciro
      expect((receipt['total_amount'] as num).toDouble(), 70.0); // Gerçekleşen ciro
    });
  });
}
