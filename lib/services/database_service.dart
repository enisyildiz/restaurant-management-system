import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

import '../models/table_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('restaurant_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;
    
    // Uygulama versiyonu degisse bile verilerin silinmemesi icin kalici bir konum seciyoruz.
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocDir.path, 'RestaurantApp', filePath);
    
    final Directory appDocDirFolder = Directory(dirname(dbPath));
    if (!await appDocDirFolder.exists()) {
      await appDocDirFolder.create(recursive: true);
    }

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE receipts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_id INTEGER NOT NULL,
  table_code TEXT,
  table_area TEXT,
  table_name TEXT NOT NULL,
  total_amount REAL NOT NULL,
  total_paid REAL NOT NULL,
  cash_paid REAL NOT NULL,
  card_paid REAL NOT NULL,
  date_closed TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE receipt_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  receipt_id INTEGER NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  product_category TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  FOREIGN KEY (receipt_id) REFERENCES receipts (id) ON DELETE CASCADE
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE receipts ADD COLUMN table_code TEXT;');
      await db.execute('ALTER TABLE receipts ADD COLUMN table_area TEXT;');
    }
  }

  Future<void> saveClosedTable(TableModel table) async {
    // BURASI ÇOK KRİTİK: Veritabanı işlemi asenkron olduğu için (await kullandığımız için)
    // işlem bitene kadar UI thread'i masayı temizliyor ve her şeyi 0 hesaplıyordu.
    // Bu yüzden değerleri asenkron bekleyişe (await instance.database) GİRMEDEN ÖNCE hesaplayıp kopyalıyoruz.
    final double totalAmount = table.currentTotal;
    final double totalPaid = table.totalPaid;
    final double cashPaid = table.totalCashPaid;
    final double cardPaid = table.totalCardPaid;
    final int tableId = table.id;
    final String tableCode = table.code;
    final String tableArea = table.area;
    final String tableName = table.name;
    
    // Ürünleri de kopyalıyoruz çünkü asıl liste anında siliniyor!
    final clonedOrders = table.orders.map((o) => {
      'product_id': o.product.id,
      'product_name': o.product.name,
      'product_category': o.product.category,
      'quantity': o.quantity,
      'price': o.product.price,
    }).toList();

    final db = await instance.database;
    
    final receiptId = await db.insert('receipts', {
      'table_id': tableId,
      'table_code': tableCode,
      'table_area': tableArea,
      'table_name': tableName,
      'total_amount': totalAmount,
      'total_paid': totalPaid,
      'cash_paid': cashPaid,
      'card_paid': cardPaid,
      'date_closed': DateTime.now().toIso8601String(),
    });

    for (var orderMap in clonedOrders) {
      await db.insert('receipt_items', {
        'receipt_id': receiptId,
        'product_id': orderMap['product_id'],
        'product_name': orderMap['product_name'],
        'product_category': orderMap['product_category'],
        'quantity': orderMap['quantity'],
        'price': orderMap['price'],
      });
    }
  }

  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    final db = await instance.database;
    return await db.query('receipts', orderBy: 'date_closed DESC');
  }
  
  Future<List<Map<String, dynamic>>> getReceiptItems(int receiptId) async {
    final db = await instance.database;
    return await db.query('receipt_items', where: 'receipt_id = ?', whereArgs: [receiptId]);
  }
}
