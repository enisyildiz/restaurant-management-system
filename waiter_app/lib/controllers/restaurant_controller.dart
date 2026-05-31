import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> printReceipt(int tableId) async {
    final table = tables.firstWhere((t) => t.id == tableId);
    
    if (table.orders.isEmpty) return;

    // 1. PDF Fişi Oluştur
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('BALIKÇI SÜLEYMAN', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text('Masa No: $tableId', style: pw.TextStyle(fontSize: 18)),
              pw.Divider(),
              // Sepetteki ürünleri dinamik olarak PDF'e bas
              ...table.orders.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item.quantity}x ${item.product.name}'),
                  pw.Text('${item.totalPrice.toStringAsFixed(2)} TL'),
                ],
              )).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOPLAM:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${table.totalBill.toStringAsFixed(2)} TL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // 2. Yazıcıya Gönder (Varsayılan Windows yazıcısını bularak yollar)
    try {
      // a. Sisteme bağlı tüm yazıcıları çek
      final printers = await Printing.listPrinters();
      
      if (printers.isEmpty) {
        debugPrint("Sistemde kurulu yazıcı bulunamadı!");
        return; // Yazıcı yoksa işlemi durdur
      }

      // b. Windows'ta "Varsayılan" (Default) olarak ayarlanmış yazıcıyı bul. 
      // Eğer varsayılan ayarlanmamışsa, listedeki ilk yazıcıyı al.
      final myPrinter = printers.firstWhere(
        (p) => p.isDefault, 
        orElse: () => printers.first
      );

      // c. Fişi seçili yazıcıya gönder
      await Printing.directPrintPdf(
        printer: myPrinter, // Hatanın çözümü olan zorunlu parametre
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      
    } catch (e) {
      debugPrint("Yazdırma Hatası: $e");
    }

    notifyListeners();
  }
}