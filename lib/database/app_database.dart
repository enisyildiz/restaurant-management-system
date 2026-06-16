import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static bool _ffiInitialized = false;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    _initializeDatabaseFactoryForDesktop();

    final databaseDirectory = await getDatabasesPath();

    final databasePath = join(
      databaseDirectory,
      'restaurant_order_app.db',
    );

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  void _initializeDatabaseFactoryForDesktop() {
    if (kIsWeb) return;

    if (_ffiInitialized) return;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sales_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        table_code TEXT NOT NULL,
        created_at TEXT NOT NULL,

        product_id TEXT,
        product_name TEXT,
        category_name TEXT,
        quantity INTEGER,
        unit_price REAL,
        total_price REAL,

        payment_amount REAL,
        payment_method TEXT,

        note TEXT
      )
    ''');
  }

  Future<int> insertSalesEvent({
    required String eventType,
    required String tableCode,
    required DateTime createdAt,
    String? productId,
    String? productName,
    String? categoryName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    double? paymentAmount,
    String? paymentMethod,
    String? note,
  }) async {
    final db = await database;

    return db.insert(
      'sales_events',
      {
        'event_type': eventType,
        'table_code': tableCode,
        'created_at': createdAt.toIso8601String(),
        'product_id': productId,
        'product_name': productName,
        'category_name': categoryName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'payment_amount': paymentAmount,
        'payment_method': paymentMethod,
        'note': note,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllSalesEvents() async {
    final db = await database;

    return db.query(
      'sales_events',
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTodaysSalesEvents() async {
    final db = await database;

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return db.query(
      'sales_events',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        startOfNextDay.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
  }

  Future<double> getTodaysTotalSales() async {
    final db = await database;

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery(
      '''
      SELECT SUM(payment_amount) AS total
      FROM sales_events
      WHERE event_type = ?
      AND created_at >= ?
      AND created_at < ?
      ''',
      [
        'payment_taken',
        startOfDay.toIso8601String(),
        startOfNextDay.toIso8601String(),
      ],
    );

    final value = result.first['total'];

    if (value == null) {
      return 0;
    }

    return (value as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getTopProductsToday() async {
    final db = await database;

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return db.rawQuery(
      '''
      SELECT 
        product_name,
        category_name,
        SUM(quantity) AS total_quantity,
        SUM(total_price) AS total_revenue
      FROM sales_events
      WHERE event_type = ?
      AND created_at >= ?
      AND created_at < ?
      GROUP BY product_name, category_name
      ORDER BY total_quantity DESC
      ''',
      [
        'order_added',
        startOfDay.toIso8601String(),
        startOfNextDay.toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentSummaryToday() async {
    final db = await database;

    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return db.rawQuery(
      '''
      SELECT 
        payment_method,
        SUM(payment_amount) AS total_amount
      FROM sales_events
      WHERE event_type = ?
      AND created_at >= ?
      AND created_at < ?
      GROUP BY payment_method
      ''',
      [
        'payment_taken',
        startOfDay.toIso8601String(),
        startOfNextDay.toIso8601String(),
      ],
    );
  }

  Future<void> deleteAllSalesEvents() async {
    final db = await database;

    await db.delete('sales_events');
  }
}