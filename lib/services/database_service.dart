import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

import '../models/table_model.dart';

class DatabaseService {
  static const int _databaseVersion = 5;
  static final DatabaseService instance = DatabaseService._init();
  Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('database.db');
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
        version: _databaseVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        table_id INTEGER NOT NULL,
        table_code TEXT,
        table_area TEXT,
        table_name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        total_paid REAL NOT NULL,
        cash_paid REAL NOT NULL,
        card_paid REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0,
        date_closed TEXT NOT NULL
      )
''');

    await db.execute('''
CREATE TABLE receipt_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  receipt_id INTEGER NOT NULL,
  session_id INTEGER,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  product_category TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  FOREIGN KEY (receipt_id) REFERENCES receipts (id) ON DELETE CASCADE
)
''');
    await _createAnalyticsTables(db);
  }

Future<void> _createAnalyticsTables(Database db) async {
          await db.execute('''
      CREATE TABLE IF NOT EXISTS table_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        table_id INTEGER NOT NULL,
        table_code TEXT NOT NULL,
        table_area TEXT NOT NULL,
        table_name TEXT NOT NULL,

        seated_at TEXT NOT NULL,
        left_at TEXT,

        status TEXT NOT NULL,

        total_ordered REAL NOT NULL DEFAULT 0,
        total_paid REAL NOT NULL DEFAULT 0,
        cash_paid REAL NOT NULL DEFAULT 0,
        card_paid REAL NOT NULL DEFAULT 0,
        discount_amount REAL NOT NULL DEFAULT 0
      )
      ''');

          await db.execute('''
      CREATE TABLE IF NOT EXISTS order_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        session_id INTEGER NOT NULL,

        table_id INTEGER NOT NULL,
        table_code TEXT NOT NULL,
        table_area TEXT NOT NULL,
        table_name TEXT NOT NULL,

        event_type TEXT NOT NULL,
        created_at TEXT NOT NULL,

        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_category TEXT NOT NULL,

        quantity_delta INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,

        username TEXT,
        user_role TEXT,

        FOREIGN KEY (session_id) REFERENCES table_sessions (id) ON DELETE CASCADE
      )
      ''');

          await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        session_id INTEGER NOT NULL,

        table_id INTEGER NOT NULL,
        table_code TEXT NOT NULL,
        table_area TEXT NOT NULL,
        table_name TEXT NOT NULL,

        created_at TEXT NOT NULL,

        payment_method TEXT NOT NULL,
        amount REAL NOT NULL,

        username TEXT,
        user_role TEXT,

        FOREIGN KEY (session_id) REFERENCES table_sessions (id) ON DELETE CASCADE
      )
      ''');

          await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_table_sessions_seated_at
      ON table_sessions(seated_at)
      ''');

          await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_table_sessions_left_at
      ON table_sessions(left_at)
      ''');

          await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_order_events_created_at
      ON order_events(created_at)
      ''');

          await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_order_events_product
      ON order_events(product_id, product_name)
      ''');

          await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_order_events_category
      ON order_events(product_category)
      ''');

          await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payment_events_created_at
      ON payment_events(created_at)
      ''');

          await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payment_events_method
      ON payment_events(payment_method)
      ''');
        }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE receipts ADD COLUMN table_code TEXT;');
      await db.execute('ALTER TABLE receipts ADD COLUMN table_area TEXT;');
    }

    if (oldVersion < 3) {
      await _createAnalyticsTables(db);
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE receipts ADD COLUMN session_id INTEGER;');
    }
    
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE receipts ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0;');
      await db.execute('ALTER TABLE table_sessions ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0;');
      await db.execute('ALTER TABLE receipt_items ADD COLUMN session_id INTEGER;');
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
    final double discountAmount = table.totalDiscount;
    final int tableId = table.id;
    final int? sessionId = table.activeSessionId;
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
      'discount_amount': discountAmount,
      'date_closed': DateTime.now().toIso8601String(),
    });

    for (var orderMap in clonedOrders) {
      await db.insert('receipt_items', {
        'session_id': sessionId,
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

  Future<int> createTableSession({
    required int tableId,
    required String tableCode,
    required String tableArea,
    required String tableName,
    required DateTime seatedAt,
  }) async {
    final db = await instance.database;

    return db.insert('table_sessions', {
      'table_id': tableId,
      'table_code': tableCode,
      'table_area': tableArea,
      'table_name': tableName,
      'seated_at': seatedAt.toIso8601String(),
      'left_at': null,
      'status': 'open',
      'total_ordered': 0.0,
      'total_paid': 0.0,
      'cash_paid': 0.0,
      'card_paid': 0.0,
    });
  }

  Future<void> closeTableSession({
    required int sessionId,
    required DateTime leftAt,
    required double totalOrdered,
    required double totalPaid,
    required double cashPaid,
    required double cardPaid,
    required double discountAmount,
  }) async {
    final db = await instance.database;

    await db.update(
      'table_sessions',
      {
        'left_at': leftAt.toIso8601String(),
        'status': 'closed',
        'total_ordered': totalOrdered,
        'total_paid': totalPaid,
        'cash_paid': cashPaid,
        'card_paid': cardPaid,
        'discount_amount': discountAmount,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> insertOrderEvent({
    required int sessionId,
    required int tableId,
    required String tableCode,
    required String tableArea,
    required String tableName,
    required String eventType,
    required DateTime createdAt,
    required int productId,
    required String productName,
    required String productCategory,
    required double quantityDelta,
    required double unitPrice,
    required double totalPrice,
    String? username,
    String? userRole,
  }) async {
    final db = await instance.database;

    await db.insert('order_events', {
      'session_id': sessionId,
      'table_id': tableId,
      'table_code': tableCode,
      'table_area': tableArea,
      'table_name': tableName,
      'event_type': eventType,
      'created_at': createdAt.toIso8601String(),
      'product_id': productId,
      'product_name': productName,
      'product_category': productCategory,
      'quantity_delta': quantityDelta,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'username': username,
      'user_role': userRole,
    });

    await db.rawUpdate(
      '''
      UPDATE table_sessions
      SET total_ordered = total_ordered + ?
      WHERE id = ?
      ''',
      [
        totalPrice,
        sessionId,
      ],
    );
  }

  Future<void> insertPaymentEvent({
    required int sessionId,
    required int tableId,
    required String tableCode,
    required String tableArea,
    required String tableName,
    required DateTime createdAt,
    required String paymentMethod,
    required double amount,
    String? username,
    String? userRole,
  }) async {
    final db = await instance.database;

    await db.insert('payment_events', {
      'session_id': sessionId,
      'table_id': tableId,
      'table_code': tableCode,
      'table_area': tableArea,
      'table_name': tableName,
      'created_at': createdAt.toIso8601String(),
      'payment_method': paymentMethod,
      'amount': amount,
      'username': username,
      'user_role': userRole,
    });

    final cashIncrement = paymentMethod == 'cash' ? amount : 0.0;
    final cardIncrement = paymentMethod == 'credit_card' ? amount : 0.0;

    await db.rawUpdate(
      '''
      UPDATE table_sessions
      SET 
        total_paid = total_paid + ?,
        cash_paid = cash_paid + ?,
        card_paid = card_paid + ?
      WHERE id = ?
      ''',
      [
        amount,
        cashIncrement,
        cardIncrement,
        sessionId,
      ],
    );
  }
  Future<List<Map<String, dynamic>>> getRecentTableSessions({
    int limit = 20,
  }) async {
    final db = await instance.database;

    return db.query(
      'table_sessions',
      orderBy: 'seated_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentOrderEvents({
    int limit = 50,
  }) async {
    final db = await instance.database;

    return db.query(
      'order_events',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentPaymentEvents({
    int limit = 50,
  }) async {
    final db = await instance.database;

    return db.query(
      'payment_events',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getTopProductsBetween({
  required DateTime start,
  required DateTime end,
  int limit = 20,
}) async {
  final db = await instance.database;

  return db.rawQuery(
    '''
    SELECT
      product_id,
      product_name,
      product_category,
      SUM(quantity_delta) AS total_quantity,
      SUM(total_price) AS total_revenue
    FROM order_events
    WHERE created_at >= ?
      AND created_at < ?
      AND event_type IN ('order_added', 'item_removed')
    GROUP BY product_id, product_name, product_category
    HAVING SUM(quantity_delta) > 0 OR SUM(total_price) > 0
    ORDER BY total_quantity DESC
    LIMIT ?
    ''',
    [
      start.toIso8601String(),
      end.toIso8601String(),
      limit,
    ],
  );
}

  Future<List<Map<String, dynamic>>> getTopProductsByRevenueBetween({
    required DateTime start,
    required DateTime end,
    int limit = 20,
  }) async {
    final db = await instance.database;

    return db.rawQuery(
      '''
      SELECT
        product_id,
        product_name,
        product_category,
        SUM(quantity_delta) AS total_quantity,
        SUM(total_price) AS total_revenue
      FROM order_events
      WHERE created_at >= ?
        AND created_at < ?
        AND event_type IN ('order_added', 'item_removed')
      GROUP BY product_id, product_name, product_category
      HAVING SUM(quantity_delta) > 0 OR SUM(total_price) > 0
      ORDER BY total_revenue DESC
      LIMIT ?
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
        limit,
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getTodaysTopProductsByRevenue({
    int limit = 20,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getTopProductsByRevenueBetween(
      start: start,
      end: end,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getTodaysTopProducts({
    int limit = 20,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getTopProductsBetween(
      start: start,
      end: end,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getCategoryRevenueBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;

    return db.rawQuery(
      '''
      SELECT
        product_category,
        SUM(quantity_delta) AS total_quantity,
        SUM(total_price) AS total_revenue
      FROM order_events
      WHERE created_at >= ?
        AND created_at < ?
        AND event_type = 'order_added'
      GROUP BY product_category
      ORDER BY total_revenue DESC
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getTodaysCategoryRevenue() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getCategoryRevenueBetween(
      start: start,
      end: end,
    );
  }

  Future<List<Map<String, dynamic>>> getHourlyOrderRevenueBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;

    return db.rawQuery(
      '''
      SELECT
        strftime('%H', created_at) AS hour,
        SUM(total_price) AS total_revenue
      FROM order_events
      WHERE created_at >= ?
        AND created_at < ?
        AND event_type = 'order_added'
      GROUP BY strftime('%H', created_at)
      ORDER BY hour ASC
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getTodaysHourlyOrderRevenue() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getHourlyOrderRevenueBetween(
      start: start,
      end: end,
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentSummaryBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;

    return db.rawQuery(
      '''
      SELECT
        payment_method,
        SUM(amount) AS total_amount,
        COUNT(*) AS payment_count
      FROM payment_events
      WHERE created_at >= ?
        AND created_at < ?
      GROUP BY payment_method
      ORDER BY total_amount DESC
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getTodaysPaymentSummary() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getPaymentSummaryBetween(
      start: start,
      end: end,
    );
  }

  Future<double> getAverageSittingDurationMinutesBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      '''
      SELECT
        AVG(strftime('%s', left_at) - strftime('%s', seated_at)) AS avg_seconds
      FROM table_sessions
      WHERE status = 'closed'
        AND left_at IS NOT NULL
        AND seated_at >= ?
        AND seated_at < ?
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    final value = result.first['avg_seconds'];

    if (value == null) {
      return 0;
    }

    return (value as num).toDouble() / 60.0;
  }

  Future<double> getAverageSittingDurationMinutesToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getAverageSittingDurationMinutesBetween(
      start: start,
      end: end,
    );
  }
Future<List<Map<String, dynamic>>> getReceiptsWithSessionInfo({
  int limit = 100,
}) async {
  final db = await instance.database;

  return db.rawQuery(
    '''
    SELECT
      r.id,
      r.session_id,
      r.table_id,
      r.table_code,
      r.table_area,
      r.table_name,
      r.total_amount,
      r.total_paid,
      r.cash_paid,
      r.card_paid,
      r.date_closed,

      ts.seated_at,
      ts.left_at,
      ts.status AS session_status,
      ts.total_ordered AS session_total_ordered,
      ts.total_paid AS session_total_paid,

      CASE
        WHEN ts.seated_at IS NOT NULL AND ts.left_at IS NOT NULL
        THEN (strftime('%s', ts.left_at) - strftime('%s', ts.seated_at)) / 60.0
        ELSE NULL
      END AS sitting_duration_minutes

    FROM receipts r
    LEFT JOIN table_sessions ts
      ON r.session_id = ts.id

    ORDER BY r.date_closed DESC
    LIMIT ?
    ''',
    [limit],
  );
}
  Future<double> getBusinessRevenueBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      '''
      SELECT SUM(total_price) AS total
      FROM order_events
      WHERE created_at >= ?
        AND created_at < ?
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    final value = result.first['total'];

    if (value == null) {
      return 0;
    }

    return (value as num).toDouble();
  }

  Future<double> getTodaysBusinessRevenue() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return getBusinessRevenueBetween(
      start: start,
      end: end,
    );
  }
    Future<List<Map<String, dynamic>>> getSessionOrderDetails({
    required int sessionId,
  }) async {
    final db = await instance.database;

    return db.rawQuery(
      '''
      SELECT
        product_id,
        product_name,
        product_category,
        SUM(quantity_delta) AS total_quantity,
        SUM(total_price) AS total_price
      FROM order_events
      WHERE session_id = ?
        AND event_type IN ('order_added', 'item_removed')
      GROUP BY product_id, product_name, product_category
      HAVING total_quantity != 0 OR total_price != 0
      ORDER BY product_category ASC, product_name ASC
      ''',
      [sessionId],
    );
  }

Future<List<Map<String, dynamic>>> getTodaysProductSales({
  int limit = 1000,
}) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));

  final db = await instance.database;

  return db.rawQuery(
    '''
    SELECT
      product_id,
      product_name,
      product_category,
      SUM(quantity_delta) AS total_quantity,
      SUM(total_price) AS total_revenue
    FROM order_events
    WHERE created_at >= ?
      AND created_at < ?
      AND event_type IN ('order_added', 'item_removed')
    GROUP BY product_id, product_name, product_category
    HAVING SUM(quantity_delta) > 0 OR SUM(total_price) > 0
    LIMIT ?
    ''',
    [
      start.toIso8601String(),
      end.toIso8601String(),
      limit,
    ],
  );
}
Future<void> updateActiveSessionTableInfo({
  required int sessionId,
  required int tableId,
  required String tableCode,
  required String tableArea,
  required String tableName,
}) async {
  final db = await instance.database;

  final values = {
    'table_id': tableId,
    'table_code': tableCode,
    'table_area': tableArea,
    'table_name': tableName,
  };

  await db.transaction((txn) async {
    await txn.update(
      'table_sessions',
      values,
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    await txn.update(
      'order_events',
      values,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    await txn.update(
      'payment_events',
      values,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  });
}
Future<List<double>> getHourlyBusinessRevenueForDate(DateTime date) async {
  final db = await instance.database;

  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));

  final result = await db.rawQuery(
    '''
    SELECT
      CAST(substr(created_at, 12, 2) AS INTEGER) AS hour,
      SUM(total_price) AS total
    FROM order_events
    WHERE created_at >= ?
      AND created_at < ?
    GROUP BY CAST(substr(created_at, 12, 2) AS INTEGER)
    ORDER BY hour ASC
    ''',
    [
      start.toIso8601String(),
      end.toIso8601String(),
    ],
  );

  final hourlyTotals = List<double>.filled(24, 0);

  for (final row in result) {
    final hour = ((row['hour'] as num?) ?? 0).toInt();
    final total = ((row['total'] as num?) ?? 0).toDouble();

    if (hour >= 0 && hour < 24) {
      hourlyTotals[hour] = total;
    }
  }

  return hourlyTotals;
}
Future<List<Map<String, dynamic>>> getDailyBusinessRevenueRowsBetween({
  required DateTime start,
  required DateTime end,
}) async {
  final db = await instance.database;

  return db.rawQuery(
    '''
    SELECT
      substr(created_at, 1, 10) AS day,
      SUM(total_price) AS total_revenue
    FROM order_events
    WHERE created_at >= ?
      AND created_at < ?
      AND event_type IN ('order_added', 'item_removed')
    GROUP BY substr(created_at, 1, 10)
    ORDER BY day ASC
    ''',
    [
      start.toIso8601String(),
      end.toIso8601String(),
    ],
  );
}

Future<List<Map<String, dynamic>>> getProductSalesBetween({
  required DateTime start,
  required DateTime end,
  int limit = 100,
}) async {
  final db = await instance.database;

  return db.rawQuery(
    '''
    SELECT
      product_id,
      product_name,
      product_category,
      SUM(quantity_delta) AS total_quantity,
      SUM(total_price) AS total_revenue
    FROM order_events
    WHERE created_at >= ?
      AND created_at < ?
      AND event_type IN ('order_added', 'item_removed')
    GROUP BY product_id, product_name, product_category
    HAVING SUM(quantity_delta) > 0 OR SUM(total_price) > 0
    ORDER BY total_revenue DESC
    LIMIT ?
    ''',
    [
      start.toIso8601String(),
      end.toIso8601String(),
      limit,
    ],
  );
}

Future<List<Map<String, dynamic>>> getAverageTableOrderByDayBetween({
  required DateTime start,
  required DateTime end,
}) async {
  final db = await instance.database;

  return db.rawQuery(
    '''
    SELECT
      substr(seated_at, 1, 10) AS day,
      AVG(total_ordered) AS avg_order,
      COUNT(*) AS table_count
    FROM table_sessions
    WHERE seated_at >= ?
      AND seated_at < ?
      AND total_ordered > 0
    GROUP BY substr(seated_at, 1, 10)
    ORDER BY day ASC
    ''',
    [
      start.toIso8601String(),
      end.toIso8601String(),
    ],
  );
}
}