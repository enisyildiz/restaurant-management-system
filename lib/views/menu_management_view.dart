import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/product.dart';
import '../theme/theme.dart';

class MenuManagementView extends StatefulWidget {
  final RestaurantController controller;

  const MenuManagementView({super.key, required this.controller});

  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  late List<Product> _tempMenu;
  late List<String> _tempCategories;
  
  final ScrollController _productScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Copy the current lists to work on locally
    _tempMenu = widget.controller.menu.map((p) => Product(
      id: p.id,
      name: p.name,
      price: p.price,
      category: p.category,
    )).toList();
    
    _tempCategories = List.from(widget.controller.editableCategories);
  }

  void _saveAll() async {
    await widget.controller.saveCategories(_tempCategories);
    await widget.controller.saveMenu(_tempMenu);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değişiklikler başarıyla kaydedildi!'), backgroundColor: AppTheme.pastelGreen),
      );
      Navigator.pop(context);
    }
  }

  void _showProductDialog({Product? product, int? index}) {
    final isEditing = product != null && index != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    
    // Ensure the default category is one of the existing ones
    String? selectedCategory = product?.category;
    if (_tempCategories.isNotEmpty && (selectedCategory == null || !_tempCategories.contains(selectedCategory))) {
      selectedCategory = _tempCategories.first;
    }

    if (_tempCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce kategori ekleyin!'), backgroundColor: AppTheme.pastelOrange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Ürün Adı'),
                  ),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Fiyat (TL)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: _tempCategories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCategory = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelGreen, foregroundColor: Colors.white),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final category = selectedCategory;

                    if (name.isEmpty || price <= 0 || category == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen geçerli değerler girin!'), backgroundColor: AppTheme.pastelRed),
                      );
                      return;
                    }

                    setState(() {
                      if (isEditing) {
                        _tempMenu[index] = Product(
                          id: product.id,
                          name: name,
                          price: price,
                          category: category,
                        );
                      } else {
                        int nextId = 1;
                        if (_tempMenu.isNotEmpty) {
                          nextId = _tempMenu.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
                        }
                        _tempMenu.add(Product(
                          id: nextId,
                          name: name,
                          price: price,
                          category: category,
                        ));
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmek istediğinize emin misiniz?'),
        content: Text('${_tempMenu[index].name} adlı ürünü silmek üzeresiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelRed),
            onPressed: () {
              setState(() {
                _tempMenu.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({String? category, int? index}) {
    final isEditing = category != null && index != null;
    final nameCtrl = TextEditingController(text: category ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Kategori Düzenle' : 'Yeni Kategori Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Kategori Adı'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelGreen, foregroundColor: Colors.white),
              onPressed: () {
                final name = nameCtrl.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen geçerli kategori adı girin!'), backgroundColor: AppTheme.pastelRed),
                  );
                  return;
                }
                
                if (_tempCategories.contains(name) && (!isEditing || _tempCategories[index] != name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu kategori zaten var!'), backgroundColor: AppTheme.pastelRed),
                  );
                  return;
                }

                setState(() {
                  if (isEditing) {
                    final oldName = _tempCategories[index];
                    _tempCategories[index] = name;
                    
                    // Update products that use this category
                    for (int i = 0; i < _tempMenu.length; i++) {
                        if (_tempMenu[i].category == oldName) {
                            _tempMenu[i] = Product(
                                id: _tempMenu[i].id, 
                                name: _tempMenu[i].name, 
                                price: _tempMenu[i].price, 
                                category: name
                            );
                        }
                    }
                  } else {
                    _tempCategories.add(name);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(int index) {
    final catName = _tempCategories[index];
    final hasProducts = _tempMenu.any((p) => p.category == catName);

    if (hasProducts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kategoriye ait ürünler var! Önce ürünleri silin veya kategorisini değiştirin.'), backgroundColor: AppTheme.pastelRed),
        );
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmek istediğinize emin misiniz?'),
        content: Text('$catName adlı kategoriyi silmek üzeresiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelRed),
            onPressed: () {
              setState(() {
                _tempCategories.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Menü Yönetimi'),
          backgroundColor: AppTheme.surfaceLight,
          iconTheme: const IconThemeData(color: AppTheme.textDark),
          titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Ürün Yönetimi'),
              Tab(text: 'Kategori Yönetimi'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _saveAll,
                icon: const Icon(Icons.save),
                label: const Text('Değişiklikleri Kaydet'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelGreen, foregroundColor: Colors.white),
              ),
            )
          ],
        ),
        body: TabBarView(
          children: [
            _buildProductsTab(),
            _buildCategoriesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'addProduct',
                onPressed: () => _showProductDialog(),
                backgroundColor: AppTheme.pastelGreen,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Yeni Ürün', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
            ),
            child: Scrollbar(
              controller: _productScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _productScrollController,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.primary.withOpacity(0.1)),
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ürün Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Fiyat (TL)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _tempMenu.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text(product.id.toString())),
                          DataCell(Text(product.name)),
                          DataCell(Text(product.category)),
                          DataCell(Text('${product.price.toStringAsFixed(2)} ₺')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                                  onPressed: () => _showProductDialog(product: product, index: index),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.pastelRed),
                                  onPressed: () => _deleteProduct(index),
                                  tooltip: 'Sil',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'addCategory',
                onPressed: () => _showCategoryDialog(),
                backgroundColor: AppTheme.pastelGreen,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Yeni Kategori', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
            ),
            child: Scrollbar(
              controller: _categoryScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _categoryScrollController,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.primary.withOpacity(0.1)),
                    columns: const [
                      DataColumn(label: Text('Kategori Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ürün Sayısı', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _tempCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final count = _tempMenu.where((p) => p.category == category).length;
                      return DataRow(
                        cells: [
                          DataCell(Text(category)),
                          DataCell(Text(count.toString())),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                                  onPressed: () => _showCategoryDialog(category: category, index: index),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.pastelRed),
                                  onPressed: () => _deleteCategory(index),
                                  tooltip: 'Sil',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
