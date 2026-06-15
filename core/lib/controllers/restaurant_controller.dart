import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product.dart';
import '../models/table_model.dart';
import '../models/order_item.dart';
import '../globals.dart';

enum PrintTarget { 
  kitchen, 
  cashier 
}

class RestaurantController extends ChangeNotifier {
  List<Product> _menu = [];
  bool isLoadingMenu = true;
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
      final String response = await rootBundle.loadString('packages/core/assets/menu.json');
      final List<dynamic> data = json.decode(response);
      _menu = data.map((jsonItem) => Product.fromJson(jsonItem)).toList();
      
      // JSON yüklendikten sonra kategorileri otomatik olarak belirle
      categories = ['Tümü', ..._menu.map((e) => e.category).toSet()];
      
      isLoadingMenu = false;
      notifyListeners();
    } catch (e) {
      _showSnackbar("JSON yüklenirken hata oluştu: $e", true);
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

  Future<void> printReceipt(int tableId, PrintTarget target) async {
    final table = tables.firstWhere((t) => t.id == tableId);
    final List<Printer> printers = await Printing.listPrinters();

    String targetPrinterName = target == PrintTarget.kitchen ? 'MUTFAK' : 'KASA';

    Printer? selectedPrinter;

    if (table.orders.isEmpty) return;

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
              ..._buildOrderRows(table.orders, target),
              if (target == PrintTarget.cashier) ...[
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOPLAM:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${table.totalBill.toStringAsFixed(2)} TL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold),),
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
                '${item.quantity}x  ${item.product.name}',
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
              pw.Text('${item.quantity}x ${item.product.name}'),
              pw.Text('${item.totalPrice.toStringAsFixed(2)} TL'),
            ],
          ),
        );
      }
      
    }).toList();
  }

  void moveTable(int currentTableId, int targetTableId) {
    // 1. Mevcut ve hedef masaları listeden bul
    //
    // (Kendi model/değişken isimlerine göre 'tables' kısmını güncelle)
    final currentTable = tables.firstWhere((t) => t.id == currentTableId);
    final targetTable = tables.firstWhere((t) => t.id == targetTableId);

    // 2. Hedef masa boş mu kontrol et (içinde sipariş var mı?)
    if (targetTable.orders.isNotEmpty) {
      // Daha önce kurduğumuz global mesaj sistemiyle hata fırlat ve işlemi kes
      _showSnackbar('Taşıma başarısız: Hedef masa boş değil!', false);
      return; 
    }

    // 3. Transfer işlemini gerçekleştir
    targetTable.orders.addAll(currentTable.orders);
    
    // (Eğer modelinde masaya ait toplam tutar vb. ekstra alanlar varsa onları da aktar)
    // targetTable.totalBill = currentTable.totalBill; 

    // 4. Eski masayı tamamen temizle
    currentTable.orders.clear();
    // currentTable.totalBill = 0.0;

    // 5. Başarı mesajı ver ve arayüzü güncelle
    _showSnackbar('Masa başarıyla taşındı.', true);
    notifyListeners();
  }
}