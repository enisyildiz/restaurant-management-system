import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product.dart';
import '../models/table_model.dart';
import '../models/order_item.dart';
import '../models/order_group.dart';
import '../models/payment_record.dart';
import '../models/user_role.dart';
import '../services/network_service.dart';
import '../services/database_service.dart';
import '../services/logger_service.dart';
import '../globals.dart';

enum PrintTarget { 
  kitchen, 
  cashier 
}

class RestaurantController extends ChangeNotifier {
  List<Product> _menu = [];
  bool isLoadingMenu = true;
  List<String> editableCategories = [];
  List<String> get categories => editableCategories;
  String selectedCategory = '';

  List<String> editableAreas = [];
  List<String> get areas => ['Tümü', ...editableAreas];
  String selectedArea = 'Tümü';

  User? currentUser;
  NetworkService? _networkService;
  int? startupTime;

  final Map<int, Future<int?>> _sessionCreationFutures = {};

  bool login(String username, String password) {
    if (username == 'admin' && password == 'admin123') {
      currentUser = const User(username: 'admin', role: UserRole.admin);
      startupTime = DateTime.now().millisecondsSinceEpoch;
      _initNetwork();
      notifyListeners();
      return true;
    } else if (username == 'waiter' && password == 'waiter123') {
      currentUser = const User(username: 'waiter', role: UserRole.waiter);
      startupTime = DateTime.now().millisecondsSinceEpoch;
      // Garson bilgisayarında DB başlatılmıyor
      _initNetwork();
      notifyListeners();
      return true;
    }
    return false;
  }

  void _initNetwork() {
    _networkService = NetworkService(
      role: currentUser!.role,
      onMessageReceived: _handleNetworkMessage,
      onError: (String error) {
        _showSnackbar(error, true);
      },
      onConnected: _syncFullState,
    );
    _networkService!.start();
  }

  void _syncFullState() {
    if (_networkService != null) {
      _networkService!.sendMessage({
        'action': 'handshake',
        'startupTime': startupTime,
      });
    }
  }

  void _handleNetworkMessage(Map<String, dynamic> data) {
    final action = data['action'];
    
    if (action == 'handshake') {
      final remoteStartup = data['startupTime'] as int;
      if (startupTime != null && startupTime! > remoteStartup) {
        _networkService!.sendMessage({
          'action': 'request_full_state',
        });
      }
    } else if (action == 'request_full_state') {
      _networkService!.sendMessage({
        'action': 'full_state',
        'tables': tables.map((t) => t.toJson()).toList(),
        'menu': _menu.map((p) => p.toJson()).toList(),
        'categories': editableCategories,
      });
      if (data.containsKey('tables')) {
        final remoteTablesData = data['tables'] as List<dynamic>;
        final remoteTables = remoteTablesData.map((e) => TableModel.fromJson(e)).toList();
        tables.clear();
        tables.addAll(remoteTables);
      }
      
      if (data.containsKey('menu')) {
        final remoteMenuData = data['menu'] as List<dynamic>;
        _menu = remoteMenuData.map((e) => Product.fromJson(e)).toList();
      }
      if (data.containsKey('categories')) {
        final remoteCatData = data['categories'] as List<dynamic>;
        editableCategories = remoteCatData.map((e) => e.toString()).toList();
        if (editableCategories.isNotEmpty && selectedCategory.isEmpty) {
          selectedCategory = editableCategories.first;
        }
      }
      if (data.containsKey('areas')) {
        final remoteAreaData = data['areas'] as List<dynamic>;
        editableAreas = remoteAreaData.map((e) => e.toString()).toList();
      }
      
      notifyListeners();
      _showSnackbar('Veriler başarıyla eşitlendi.', false);
    } else if (action == 'sync_menu') {
      final remoteMenuData = data['menu'] as List<dynamic>;
      _menu = remoteMenuData.map((e) => Product.fromJson(e)).toList();
      notifyListeners();
      _showSnackbar('Menü sunucudan güncellendi.', false);
    } else if (action == 'sync_categories') {
      final remoteCatData = data['categories'] as List<dynamic>;
      editableCategories = remoteCatData.map((e) => e.toString()).toList();
      if (!editableCategories.contains(selectedCategory) && editableCategories.isNotEmpty) {
        selectedCategory = editableCategories.first;
      }
      notifyListeners();
      _showSnackbar('Kategoriler sunucudan güncellendi.', false);
    } else if (action == 'sync_areas') {
      final remoteAreaData = data['areas'] as List<dynamic>;
      editableAreas = remoteAreaData.map((e) => e.toString()).toList();
      notifyListeners();
      _showSnackbar('Bölgeler sunucudan güncellendi.', false);
    } else if (action == 'sync_tables') {
      final remoteTablesData = data['tables'] as List<dynamic>;
      final remoteTables = remoteTablesData.map((e) => TableModel.fromJson(e)).toList();
      tables.clear();
      tables.addAll(remoteTables);
      notifyListeners();
      _showSnackbar('Masalar sunucudan güncellendi.', false);
    } else if (action == 'add_product') {
      addProductToTable(data['tableId'], Product.fromJson(data['product']), fromNetwork: true);
    } else if (action == 'remove_product') {
      removeProductFromTable(data['tableId'], Product.fromJson(data['product']), fromNetwork: true);
    } else if (action == 'set_product_quantity') {
      setProductQuantity(data['tableId'], Product.fromJson(data['product']), (data['quantity'] as num).toDouble(), fromNetwork: true);
    } else if (action == 'checkout_table') {
        checkoutTable(data['tableId'], fromNetwork: true);
    } else if (action == 'move_table') {
      moveTable(data['currentTableId'], data['targetTableId'], fromNetwork: true);
    } else if (action == 'add_payment') {
      final methodStr = data['method'];
      final method = PaymentMethod.values.firstWhere((e) => e.toString() == methodStr);
      addPaymentToTable(tableId: data['tableId'], amount: data['amount'], method: method, fromNetwork: true);
    } else if (action == 'set_custom_price') {
      setCustomPrice(data['tableId'], data['productId'], (data['price'] as num).toDouble(), fromNetwork: true);
    }
  }

  void logout() {
    currentUser = null;
    _networkService?.dispose();
    _networkService = null;
    notifyListeners();
  }

  List<Product> get filteredMenu {
    if (selectedCategory.isEmpty || selectedCategory == 'Tümü') return _menu;
    return _menu.where((p) => p.category == selectedCategory).toList();
  }

  List<Product> get menu => _menu;

  void changeCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setCustomPrice(int tableId, int productId, double newPrice, {bool fromNetwork = false}) {
    final tableIndex = tables.indexWhere((t) => t.id == tableId);
    if (tableIndex != -1) {
      tables[tableIndex].customPrices[productId] = newPrice;
      notifyListeners();

      if (!fromNetwork && _networkService != null) {
        _networkService!.sendMessage({
          'action': 'set_custom_price',
          'tableId': tableId,
          'productId': productId,
          'price': newPrice,
        });
      }
      
      saveTables(tables);
    }
  }

  List<TableModel> tables = [];

  RestaurantController() {
    loadCategories().then((_) => loadMenu());
    loadAreas().then((_) => loadTables());
  }

  Future<void> loadTables() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'tables.json');
      final File configFile = File(configPath);
      
      String response;
      if (await configFile.exists()) {
        response = await configFile.readAsString();
      } else {
        response = '[]';
        
        final Directory appDocDirFolder = Directory(p.dirname(configPath));
        if (!await appDocDirFolder.exists()) {
          await appDocDirFolder.create(recursive: true);
        }
        await configFile.writeAsString(response);
      }

      final List<dynamic> data = json.decode(response);
      tables = data.map((jsonItem) => TableModel.fromJson(jsonItem)).toList();
      
      if (editableAreas.isEmpty && tables.isNotEmpty) {
        editableAreas = tables.map((e) => e.area).toSet().toList();
        saveAreas(editableAreas);
      }

      notifyListeners();
    } catch (e) {
      LoggerService.instance.error('Error loading tables.json: $e');
    }
  }

  Future<void> saveTables(List<TableModel> newTables) async {
    tables = newTables;
    notifyListeners();

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'tables.json');
      final File configFile = File(configPath);
      
      final String jsonStr = json.encode(tables.map((e) => e.toJson()).toList());
      await configFile.writeAsString(jsonStr);

      if (_isAdminDevice && _networkService != null) {
        _networkService!.sendMessage({
          'action': 'sync_tables',
          'tables': tables.map((e) => e.toJson()).toList(),
        });
      }
      
      _showSnackbar('Masalar başarıyla kaydedildi.', false);
    } catch (e) {
      _showSnackbar('Masalar kaydedilirken hata oluştu: $e', true);
    }
  }

  Future<void> loadMenu() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'menu.json');
      final File configFile = File(configPath);
      
      String response;
      if (await configFile.exists()) {
        response = await configFile.readAsString();
      } else {
        response = '[]';
        
        final Directory appDocDirFolder = Directory(p.dirname(configPath));
        if (!await appDocDirFolder.exists()) {
          await appDocDirFolder.create(recursive: true);
        }
        await configFile.writeAsString(response);
      }
      
      final List<dynamic> data = json.decode(response);
      _menu = data.map((jsonItem) => Product.fromJson(jsonItem)).toList();
      
      if (editableCategories.isEmpty && _menu.isNotEmpty) {
        editableCategories = _menu.map((e) => e.category).toSet().toList();
        saveCategories(editableCategories);
      }
      
      if (selectedCategory.isEmpty || selectedCategory == 'Tümü') {
        if (editableCategories.isNotEmpty) {
          selectedCategory = editableCategories.first;
        }
      }

      isLoadingMenu = false;
      notifyListeners();
    } catch (e) {
      _showSnackbar("JSON yüklenirken hata oluştu: $e", true);
      isLoadingMenu = false;
      notifyListeners();
    }
  }

  Future<void> saveMenu(List<Product> newMenu) async {
    _menu = newMenu;
    notifyListeners();

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'menu.json');
      final File configFile = File(configPath);
      
      final String jsonStr = json.encode(_menu.map((e) => e.toJson()).toList());
      await configFile.writeAsString(jsonStr);

      if (_isAdminDevice && _networkService != null) {
        _networkService!.sendMessage({
          'action': 'sync_menu',
          'menu': _menu.map((e) => e.toJson()).toList(),
        });
      }
      
      _showSnackbar('Menü başarıyla kaydedildi.', false);
    } catch (e) {
      _showSnackbar('Menü kaydedilirken hata oluştu: $e', true);
    }
  }

  Future<void> loadCategories() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'categories.json');
      final File configFile = File(configPath);
      
      if (await configFile.exists()) {
        final String response = await configFile.readAsString();
        final List<dynamic> data = json.decode(response);
        editableCategories = data.map((e) => e.toString()).toList();
      } else {
        editableCategories = [];
        final Directory appDocDirFolder = Directory(p.dirname(configPath));
        if (!await appDocDirFolder.exists()) {
          await appDocDirFolder.create(recursive: true);
        }
        await configFile.writeAsString(json.encode(editableCategories));
      }

      if (selectedCategory.isEmpty || selectedCategory == 'Tümü') {
        if (editableCategories.isNotEmpty) {
          selectedCategory = editableCategories.first;
        }
      }
      
      notifyListeners();
    } catch (e) {
      LoggerService.instance.error('Kategoriler yüklenirken hata: $e');
    }
  }

  Future<void> saveCategories(List<String> newCategories) async {
    editableCategories = newCategories;
    notifyListeners();

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'categories.json');
      final File configFile = File(configPath);
      
      final String jsonStr = json.encode(editableCategories);
      await configFile.writeAsString(jsonStr);

      if (_isAdminDevice && _networkService != null) {
        _networkService!.sendMessage({
          'action': 'sync_categories',
          'categories': editableCategories,
        });
      }
      
      _showSnackbar('Kategoriler başarıyla kaydedildi.', false);
    } catch (e) {
      _showSnackbar('Kategoriler kaydedilirken hata oluştu: $e', true);
    }
  }

  Future<void> loadAreas() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'areas.json');
      final File configFile = File(configPath);
      
      if (await configFile.exists()) {
        final String response = await configFile.readAsString();
        final List<dynamic> data = json.decode(response);
        editableAreas = data.map((e) => e.toString()).toList();
      } else {
        editableAreas = [];
        final Directory appDocDirFolder = Directory(p.dirname(configPath));
        if (!await appDocDirFolder.exists()) {
          await appDocDirFolder.create(recursive: true);
        }
        await configFile.writeAsString(json.encode(editableAreas));
      }
      notifyListeners();
    } catch (e) {
      LoggerService.instance.error('Bölgeler yüklenirken hata: $e');
    }
  }

  Future<void> saveAreas(List<String> newAreas) async {
    editableAreas = newAreas;
    notifyListeners();

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'areas.json');
      final File configFile = File(configPath);
      
      final String jsonStr = json.encode(editableAreas);
      await configFile.writeAsString(jsonStr);

      if (_isAdminDevice && _networkService != null) {
        _networkService!.sendMessage({
          'action': 'sync_areas',
          'areas': editableAreas,
        });
      }
      
      _showSnackbar('Bölgeler başarıyla kaydedildi.', false);
    } catch (e) {
      _showSnackbar('Bölgeler kaydedilirken hata oluştu: $e', true);
    }
  }

  bool get _isAdminDevice => currentUser?.role == UserRole.admin;

String? get _currentUsername => currentUser?.username;

String? get _currentUserRoleName => currentUser?.role.name;

String _paymentMethodToDatabaseValue(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'cash';
    case PaymentMethod.creditCard:
      return 'credit_card';
    case PaymentMethod.discount:
      return 'discount';
  }
}

Future<int?> _ensureActiveSessionForTable(TableModel table) async {
  if (!_isAdminDevice) {
    return table.activeSessionId;
  }

  if (table.activeSessionId != null) {
    return table.activeSessionId;
  }

  final existingFuture = _sessionCreationFutures[table.id];

  if (existingFuture != null) {
    return existingFuture;
  }

  final future = () async {
    try {
      final seatedAt = table.seatedAt ?? DateTime.now();

      table.seatedAt = seatedAt;

      final sessionId = await DatabaseService.instance.createTableSession(
        tableId: table.id,
        tableCode: table.code,
        tableArea: table.area,
        tableName: table.name,
        seatedAt: seatedAt,
      );

      table.activeSessionId = sessionId;

      return sessionId;
    } catch (e) {
      LoggerService.instance.error('Error creating table session: $e');
      return null;
    } finally {
      _sessionCreationFutures.remove(table.id);
    }
  }();

  _sessionCreationFutures[table.id] = future;

  return future;
}

void _logOrderEventIfAdmin({
  required TableModel table,
  required Product product,
  required String eventType,
  required double quantityDelta,
  required double totalPrice,
}) {
  if (!_isAdminDevice) return;

  final createdAt = DateTime.now();

  unawaited(() async {
    try {
      final sessionId = await _ensureActiveSessionForTable(table);

      if (sessionId == null) return;

      await DatabaseService.instance.insertOrderEvent(
        sessionId: sessionId,
        tableId: table.id,
        tableCode: table.code,
        tableArea: table.area,
        tableName: table.name,
        eventType: eventType,
        createdAt: createdAt,
        productId: product.id,
        productName: product.name,
        productCategory: product.category,
        quantityDelta: quantityDelta,
        unitPrice: product.price,
        totalPrice: totalPrice,
        username: _currentUsername,
        userRole: _currentUserRoleName,
      );
    } catch (e) {
      LoggerService.instance.error('Error inserting order event: $e');
    }
  }());
}

void _logPaymentEventIfAdmin({
  required TableModel table,
  required double amount,
  required PaymentMethod method,
}) {
  if (!_isAdminDevice) return;

  final createdAt = DateTime.now();

  unawaited(() async {
    try {
      final sessionId = await _ensureActiveSessionForTable(table);

      if (sessionId == null) return;

      await DatabaseService.instance.insertPaymentEvent(
        sessionId: sessionId,
        tableId: table.id,
        tableCode: table.code,
        tableArea: table.area,
        tableName: table.name,
        createdAt: createdAt,
        paymentMethod: _paymentMethodToDatabaseValue(method),
        amount: amount,
        username: _currentUsername,
        userRole: _currentUserRoleName,
      );
    } catch (e) {
      LoggerService.instance.error('Error inserting payment event: $e');
    }
  }());
}

void _closeSessionIfAdmin(TableModel table) {
  if (!_isAdminDevice) return;

  final existingSessionId = table.activeSessionId;
  final leftAt = DateTime.now();

  final tableId = table.id;
  final tableCode = table.code;
  final tableArea = table.area;
  final tableName = table.name;

  final seatedAt = table.seatedAt ?? leftAt;

  final totalOrdered = table.currentTotal;
  final totalPaid = table.totalPaid;
  final cashPaid = table.totalCashPaid;
  final cardPaid = table.totalCardPaid;
  final discountAmount = table.totalDiscount;

  unawaited(() async {
    try {
      int? sessionId = existingSessionId;

      if (sessionId == null) {
        sessionId = await _sessionCreationFutures[tableId];
      }

      sessionId ??= await DatabaseService.instance.createTableSession(
        tableId: tableId,
        tableCode: tableCode,
        tableArea: tableArea,
        tableName: tableName,
        seatedAt: seatedAt,
      );

      await DatabaseService.instance.closeTableSession(
        sessionId: sessionId,
        leftAt: leftAt,
        totalOrdered: totalOrdered,
        totalPaid: totalPaid,
        cashPaid: cashPaid,
        cardPaid: cardPaid,
        discountAmount: discountAmount,
      );
    } catch (e) {
      LoggerService.instance.error('Error closing table session: $e');
    }
  }());
}

OrderGroup _getOrCreateActiveGroup(TableModel table) {
  if (table.orderGroups.isEmpty || table.orderGroups.last.isPrintedToKitchen) {
    final newGroup = OrderGroup();
    table.orderGroups.add(newGroup);
    return newGroup;
  }
  return table.orderGroups.last;
}

void addProductToTable(
  int tableId,
  Product product, {
  bool fromNetwork = false,
}) {
  final table = tables.firstWhere((t) => t.id == tableId);
  final activeGroup = _getOrCreateActiveGroup(table);
  final existingItemIndex = activeGroup.items.indexWhere(
    (item) => item.product.id == product.id,
  );

  if (existingItemIndex >= 0) {
    activeGroup.items[existingItemIndex].quantity += 1.0;
  } else {
    activeGroup.items.add(OrderItem(product: product, orderTime: DateTime.now()));
  }

  table.status = TableStatus.occupied;
  table.seatedAt ??= DateTime.now();

  _logOrderEventIfAdmin(
    table: table,
    product: product,
    eventType: 'order_added',
    quantityDelta: 1.0,
    totalPrice: product.price,
  );

  if (!fromNetwork && _networkService != null) {
    _networkService!.sendMessage({
      'action': 'add_product',
      'tableId': tableId,
      'product': product.toJson(),
    });
  }

  notifyListeners();
}

void setProductQuantity(
  int tableId,
  Product product,
  double newQuantity, {
  bool fromNetwork = false,
}) {
  if (newQuantity <= 0) {
    if (currentUser?.role.name == 'admin') {
      removeProductFromTable(tableId, product, fromNetwork: fromNetwork);
      return;
    } else {
      newQuantity = 1.0;
    }
  }

  final table = tables.firstWhere((t) => t.id == tableId);
  final oldQuantity = table.orders.where((item) => item.product.id == product.id).fold(0.0, (sum, item) => sum + item.quantity);
  final delta = newQuantity - oldQuantity;

  if (delta == 0) return;

  if (delta > 0) {
    final activeGroup = _getOrCreateActiveGroup(table);
    final existingItemIndex = activeGroup.items.indexWhere((item) => item.product.id == product.id);
    if (existingItemIndex >= 0) {
      activeGroup.items[existingItemIndex].quantity += delta;
    } else {
      activeGroup.items.add(OrderItem(product: product, quantity: delta, orderTime: DateTime.now()));
    }
  } else {
    double amountToRemove = -delta;
    for (int i = table.orderGroups.length - 1; i >= 0; i--) {
      if (amountToRemove <= 0) break;
      final group = table.orderGroups[i];
      final itemIndex = group.items.indexWhere((item) => item.product.id == product.id);
      if (itemIndex >= 0) {
        if (group.items[itemIndex].quantity <= amountToRemove) {
          amountToRemove -= group.items[itemIndex].quantity;
          group.items.removeAt(itemIndex);
        } else {
          group.items[itemIndex].quantity -= amountToRemove;
          amountToRemove = 0;
        }
      }
      if (group.items.isEmpty && !group.isPrintedToKitchen) {
        table.orderGroups.removeAt(i);
      }
    }
  }

  table.status = TableStatus.occupied;
  table.seatedAt ??= DateTime.now();

  _logOrderEventIfAdmin(
    table: table,
    product: product,
    eventType: 'quantity_updated',
    quantityDelta: delta,
    totalPrice: product.price * delta,
  );

  if (!fromNetwork && _networkService != null) {
    _networkService!.sendMessage({
      'action': 'set_product_quantity',
      'tableId': tableId,
      'product': product.toJson(),
      'quantity': newQuantity,
    });
  }

  notifyListeners();
}

void removeProductFromTable(
  int tableId,
  Product product, {
  bool fromNetwork = false,
}) {
  final table = tables.firstWhere((t) => t.id == tableId);
  final oldQuantity = table.orders.where((item) => item.product.id == product.id).fold(0.0, (sum, item) => sum + item.quantity);

  if (oldQuantity == 0) return;

  for (int i = table.orderGroups.length - 1; i >= 0; i--) {
    final group = table.orderGroups[i];
    final itemIndex = group.items.indexWhere((item) => item.product.id == product.id);
    if (itemIndex >= 0) {
      group.items.removeAt(itemIndex);
    }
  }

  table.orderGroups.removeWhere((g) => g.items.isEmpty && !g.isPrintedToKitchen);

  _logOrderEventIfAdmin(
    table: table,
    product: product,
    eventType: 'item_removed',
    quantityDelta: -oldQuantity,
    totalPrice: -(product.price * oldQuantity),
  );

  if (table.orderGroups.isEmpty || table.orderGroups.every((g) => g.items.isEmpty)) {
    _closeSessionIfAdmin(table);
    table.status = TableStatus.empty;
    table.activeSessionId = null;
    table.seatedAt = null;
  }

  if (!fromNetwork && _networkService != null) {
    _networkService!.sendMessage({
      'action': 'remove_product',
      'tableId': tableId,
      'product': product.toJson(),
    });
  }

  notifyListeners();
}

  void checkoutTable(int tableId, {bool fromNetwork = false}) {
    final table = tables.firstWhere((t) => t.id == tableId);
    
    // Veritabanı sadece YÖNETİCİ (Admin) bilgisayarında kayıt edilecek
    // İster Admin kendisi kapasın (!fromNetwork), ister Garson kapasın ve ağdan gelsin (fromNetwork).
    // İki durumda da sadece Admin DB'ye yazar. Garson asla yazmaz.
  if (currentUser?.role == UserRole.admin && table.orders.isNotEmpty) {
    DatabaseService.instance.saveClosedTable(table);
    _closeSessionIfAdmin(table);
  }

    table.orderGroups.clear();
    table.payments.clear();
    table.status = TableStatus.empty;

    table.activeSessionId = null;
    table.seatedAt = null;
    
    if (!fromNetwork && _networkService != null) {
      _networkService!.sendMessage({
        'action': 'checkout_table',
        'tableId': tableId,
      });
    }
    notifyListeners();
  }

  void saveTable(int tableId) {
    final table = tables.firstWhere((t) => t.id == tableId);
    table.status = TableStatus.occupied;
    notifyListeners();
  }

  Future<void> printReceipt(int tableId, PrintTarget target) async {
    final table = tables.firstWhere((t) => t.id == tableId);
    final List<Printer> printers = await Printing.listPrinters();

    String targetPrinterName = target == PrintTarget.kitchen ? 'MUTFAK' : 'KASA';

    Printer? selectedPrinter;

    if (table.orderGroups.isEmpty) return;

    List<OrderItem> itemsToPrint = [];
    List<OrderGroup> unprintedGroups = [];

    if (target == PrintTarget.kitchen) {
      unprintedGroups = table.orderGroups.where((g) => !g.isPrintedToKitchen && g.items.isNotEmpty).toList();
      if (unprintedGroups.isEmpty) {
        _showSnackbar('Yazdırılacak yeni sipariş yok.', true);
        return;
      }
      itemsToPrint = unprintedGroups.expand((g) => g.items).toList();
    } else {
      itemsToPrint = table.orders;
    }

    try {
      selectedPrinter = printers.firstWhere((p) => p.name == targetPrinterName);
    } catch (e) {
      _showSnackbar('HATA: Yazıcı $targetPrinterName sistemde bulunamadı!', true);
      return; 
    }

    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('BALIKÇI SÜLEYMAN', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text('Masa No: $tableId', style: const pw.TextStyle(fontSize: 18)),
              pw.Divider(),
              ..._buildOrderRows(itemsToPrint, target),
              if (target == PrintTarget.cashier) ...[
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOPLAM:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${table.currentTotal.toStringAsFixed(2)} TL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold),),
                    ],
                  ),
                ],
            ],
          );
        },
      ),
    );

    try {
      await Printing.directPrintPdf(
        printer: selectedPrinter,
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      
      if (target == PrintTarget.kitchen) {
        for (final group in unprintedGroups) {
          group.isPrintedToKitchen = true;
        }
      }
    } catch (e) {
      _showSnackbar("Yazdırma Hatası: $e", true);
    }

    notifyListeners();
  }

  void _showSnackbar(String message, bool isFailed) {
    globalMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isFailed ? Colors.red.shade800 : Colors.green.shade800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<pw.Widget> _buildOrderRows(List<OrderItem> orders, PrintTarget target) {
    Iterable<OrderItem> itemsToPrint = orders;

    if (target == PrintTarget.kitchen) {
      itemsToPrint = orders.where((item) {
        final kategori = item.product.category.toLowerCase();
        
        return kategori != 'içecekler' && kategori != 'tatlılar'; 
      });
    }

    return itemsToPrint.map<pw.Widget>((item) {
      if (target == PrintTarget.kitchen) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                '${item.quantity == item.quantity.truncateToDouble() ? item.quantity.toInt() : item.quantity}x  ${item.product.name}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        );
      } 
      
      else {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${item.quantity == item.quantity.truncateToDouble() ? item.quantity.toInt() : item.quantity}x ${item.product.name}'),
              pw.Text('${item.totalPrice.toStringAsFixed(2)} TL'),
            ],
          ),
        );
      }
      
    }).toList();
  }

  void moveTable(int currentTableId, int targetTableId, {bool fromNetwork = false}) {
  final currentTable = tables.firstWhere((t) => t.id == currentTableId);
  final targetTable = tables.firstWhere((t) => t.id == targetTableId);

  if (targetTable.orders.isNotEmpty && !fromNetwork) {
    _showSnackbar('Taşıma başarısız: Hedef masa boş değil!', false);
    return;
  }

  final movedSessionId = currentTable.activeSessionId;

  targetTable.orderGroups.addAll(currentTable.orderGroups);
  targetTable.payments.addAll(currentTable.payments);

  // Preserve the current table status instead of always forcing occupied.
  targetTable.status = currentTable.status;

  targetTable.activeSessionId = currentTable.activeSessionId;
  targetTable.seatedAt = currentTable.seatedAt;

  if (_isAdminDevice && movedSessionId != null) {
    unawaited(
      DatabaseService.instance.updateActiveSessionTableInfo(
        sessionId: movedSessionId,
        tableId: targetTable.id,
        tableCode: targetTable.code,
        tableArea: targetTable.area,
        tableName: targetTable.name,
      ),
    );
  }

  currentTable.orderGroups.clear();
  currentTable.payments.clear();
  currentTable.status = TableStatus.empty;
  currentTable.activeSessionId = null;
  currentTable.seatedAt = null;

  if (!fromNetwork && _networkService != null) {
    _networkService!.sendMessage({
      'action': 'move_table',
      'currentTableId': currentTableId,
      'targetTableId': targetTableId,
    });
    _showSnackbar('Masa başarıyla taşındı.', true);
  }

  notifyListeners();
}

  List<OrderItem> ordersForTable(int tableId) {
    final index = tables.indexWhere((t) => t.id == tableId);
    
    if (index == -1) {
      return [];
    }
    
    return tables[index].orders; 
  }

  List<PaymentRecord> paymentsForTable(int tableId) {
    final index = tables.indexWhere((t) => t.id == tableId);
    
    if (index == -1) {
      return [];
    }
    
    return tables[index].payments; 
  }

  double totalForTable(int tableId) {
    final index = tables.indexWhere((t) => t.id == tableId);
    
    if (index == -1) {
      return 0.0;
    }

    return tables[index].currentTotal;
  }

  double totalPaidForTable(int tableId) {
    final index = tables.indexWhere((t) => t.id == tableId);
    
    if (index == -1) {
      return 0.0;
    }

    return tables[index].totalPaid;
  }

  double remainingForTable(int tableId) {
    final index = tables.indexWhere((t) => t.id == tableId);

    if (index == -1) {
      return 0.0;
    }

    final remaining = tables[index].currentTotal - tables[index].totalPaid;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  double cashPaidForTable(int tableId) {
    final index = tables.indexWhere((t) => t.id == tableId);

    if (index == -1) {
      return 0.0;
    }

    return tables[index].totalCashPaid;
  }

  double creditCardPaidForTable(int tableId) {
    final index = tables.indexWhere((t) => t.id == tableId);

    if (index == -1) {
      return 0.0;
    }

    return tables[index].totalCardPaid;
  }

  void addPaymentToTable({
    required int tableId,
    required double amount,
    required PaymentMethod method,
    bool fromNetwork = false,
  }) {
    if (amount <= 0) return;

    final remaining = remainingForTable(tableId);
    if (remaining <= 0) return;

    final safeAmount = amount > remaining ? remaining : amount;
    final index = tables.indexWhere((t) => t.id == tableId);

    if (index == -1) return;

    tables[index].payments.add(
      PaymentRecord(
        amount: safeAmount,
        method: method,
        paidAt: DateTime.now(),
      ),
    );

    _logPaymentEventIfAdmin(
      table: tables[index],
      amount: safeAmount,
      method: method,
    );

    if (!fromNetwork && _networkService != null) {
      _networkService!.sendMessage({
        'action': 'add_payment',
        'tableId': tableId,
        'amount': safeAmount,
        'method': method.toString(),
      });
    }

    final newRemaining = remainingForTable(tableId);
    if (newRemaining <= 0) {
      checkoutTable(tableId, fromNetwork: fromNetwork);
    } else {
      notifyListeners();
    }
  }
}