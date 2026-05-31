import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/table_model.dart';
import '../models/order_item.dart';

class RestaurantController extends ChangeNotifier {
  List<Product> _menu = [];
  bool isLoadingMenu = true;

  // --- YENİ EKLENEN KISIMLAR (Kategori ve Filtreleme) ---
  List<String> categories = [];
  String selectedCategory = 'Tümü';

  // Sadece seçili kategoriye ait ürünleri döndüren getter
  List<Product> get filteredMenu {
    if (selectedCategory == 'Tümü') return _menu;
    return _menu.where((p) => p.category == selectedCategory).toList();
  }

  void changeCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }
  // --------------------------------------------------------

  final List<TableModel> tables = List.generate(
    15,
    (index) => TableModel(id: index + 1, name: 'Masa ${index + 1}'),
  );

  RestaurantController() {
    loadMenu();
  }

  Future<void> loadMenu() async {
    try {
      final String response = await rootBundle.loadString('assets/menu.json');
      final List<dynamic> data = json.decode(response);
      _menu = data.map((jsonItem) => Product.fromJson(jsonItem)).toList();
      
      // JSON yüklendikten sonra kategorileri otomatik olarak belirle
      categories = ['Tümü', ..._menu.map((e) => e.category).toSet()];
      
      isLoadingMenu = false;
      notifyListeners();
    } catch (e) {
      debugPrint("JSON yüklenirken hata oluştu: $e");
      isLoadingMenu = false;
      notifyListeners();
    }
  }

  // ... (Geri kalan addProductToTable, removeProductFromTable, checkoutTable fonksiyonları aynen kalacak) ...
  void addProductToTable(int tableId, Product product) {
    final table = tables.firstWhere((t) => t.id == tableId);
    final existingItemIndex = table.orders.indexWhere((item) => item.product.id == product.id);

    if (existingItemIndex >= 0) {
      table.orders[existingItemIndex].quantity++;
    } else {
      table.orders.add(OrderItem(product: product));
    }
    table.status = TableStatus.occupied;
    notifyListeners();
  }

  void removeProductFromTable(int tableId, Product product) {
    final table = tables.firstWhere((t) => t.id == tableId);
    final existingItemIndex = table.orders.indexWhere((item) => item.product.id == product.id);

    if (existingItemIndex >= 0) {
      if (table.orders[existingItemIndex].quantity > 1) {
        table.orders[existingItemIndex].quantity--;
      } else {
        table.orders.removeAt(existingItemIndex);
      }
    }

    if (table.orders.isEmpty) table.status = TableStatus.empty;
    notifyListeners();
  }

  void checkoutTable(int tableId) {
    final table = tables.firstWhere((t) => t.id == tableId);
    table.orders.clear();
    table.status = TableStatus.empty;
    notifyListeners();
  }

  void saveTable(int tableId) {
    final table = tables.firstWhere((t) => t.id == tableId);
    table.status = TableStatus.occupied;
    notifyListeners();
  }
}