import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

import '../models/table_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  Database? _database;
  String _dbPrefix = 'default';

  DatabaseService._init();

  Future<void> initPrefix(String prefix) async {
    _dbPrefix = prefix;
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('restaurant_database_$_dbPrefix.db');
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
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE receipts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_id INTEGER NOT NULL,
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

  Future<void> saveClosedTable(TableModel table) async {
    // BURASI ÇOK KRİTİK: Veritabanı işlemi asenkron olduğu için (await kullandığımız için)
    // işlem bitene kadar UI thread'i masayı temizliyor ve her şeyi 0 hesaplıyordu.
    // Bu yüzden değerleri asenkron bekleyişe (await instance.database) GİRMEDEN ÖNCE hesaplayıp kopyalıyoruz.
    final double totalAmount = table.currentTotal;
    final double totalPaid = table.totalPaid;
    final double cashPaid = table.totalCashPaid;
    final double cardPaid = table.totalCardPaid;
    final int tableId = table.id;
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
