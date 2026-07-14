import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../theme/theme.dart';

class TableManagementView extends StatefulWidget {
  final RestaurantController controller;

  const TableManagementView({super.key, required this.controller});

  @override
  State<TableManagementView> createState() => _TableManagementViewState();
}

class _TableManagementViewState extends State<TableManagementView> {
  late List<TableModel> _tempTables;
  late List<String> _tempAreas;
  
  final ScrollController _tableScrollController = ScrollController();
  final ScrollController _areaScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Copy the current lists to work on locally
    _tempTables = widget.controller.tables.map((t) => TableModel(
      id: t.id,
      code: t.code,
      name: t.name,
      area: t.area,
      status: t.status,
      orders: List.from(t.orders),
      payments: List.from(t.payments),
      activeSessionId: t.activeSessionId,
      seatedAt: t.seatedAt,
    )).toList();
    
    _tempAreas = List.from(widget.controller.editableAreas);
  }

  void _saveAll() async {
    await widget.controller.saveAreas(_tempAreas);
    await widget.controller.saveTables(_tempTables);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değişiklikler başarıyla kaydedildi!'), backgroundColor: AppTheme.pastelMalachite),
      );
      Navigator.pop(context);
    }
  }

  void _showTableDialog({TableModel? table, int? index}) {
    final isEditing = table != null && index != null;
    final nameCtrl = TextEditingController(text: table?.name ?? '');
    final codeCtrl = TextEditingController(text: table?.code ?? '');
    
    // Ensure the default area is one of the existing ones
    String? selectedArea = table?.area;
    if (_tempAreas.isNotEmpty && (selectedArea == null || !_tempAreas.contains(selectedArea))) {
      selectedArea = _tempAreas.first;
    }

    if (_tempAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bölge ekleyin!'), backgroundColor: AppTheme.pastelOrange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Masayı Düzenle' : 'Yeni Masa Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Masa Kodu (Örn: M-1)'),
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Masa Adı (Örn: Masa 1)'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedArea,
                    decoration: const InputDecoration(labelText: 'Bölge'),
                    items: _tempAreas.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedArea = val;
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelMalachite, foregroundColor: Colors.white),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final code = codeCtrl.text.trim();
                    final area = selectedArea;

                    if (name.isEmpty || code.isEmpty || area == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen geçerli değerler girin!'), backgroundColor: AppTheme.pastelRed),
                      );
                      return;
                    }

                    setState(() {
                      if (isEditing) {
                        _tempTables[index] = TableModel(
                          id: table.id,
                          code: code,
                          name: name,
                          area: area,
                          status: table.status,
                          orders: table.orders,
                          payments: table.payments,
                          activeSessionId: table.activeSessionId,
                          seatedAt: table.seatedAt,
                        );
                      } else {
                        int nextId = 1;
                        if (_tempTables.isNotEmpty) {
                          nextId = _tempTables.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
                        }
                        _tempTables.add(TableModel(
                          id: nextId,
                          code: code,
                          name: name,
                          area: area,
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

  void _deleteTable(int index) {
    final table = _tempTables[index];
    if (table.status == TableStatus.occupied || table.orders.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dolu olan veya hesabı açık olan bir masayı silemezsiniz!'), backgroundColor: AppTheme.pastelRed),
        );
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmek istediğinize emin misiniz?'),
        content: Text('${table.name} adlı masayı silmek üzeresiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelRed),
            onPressed: () {
              setState(() {
                _tempTables.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAreaDialog({String? area, int? index}) {
    final isEditing = area != null && index != null;
    final nameCtrl = TextEditingController(text: area ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Bölgeyi Düzenle' : 'Yeni Bölge Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Bölge Adı (Örn: Bahçe)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelMalachite, foregroundColor: Colors.white),
              onPressed: () {
                final name = nameCtrl.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen geçerli bölge adı girin!'), backgroundColor: AppTheme.pastelRed),
                  );
                  return;
                }
                
                if (_tempAreas.contains(name) && (!isEditing || _tempAreas[index] != name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu bölge zaten var!'), backgroundColor: AppTheme.pastelRed),
                  );
                  return;
                }

                setState(() {
                  if (isEditing) {
                    final oldName = _tempAreas[index];
                    _tempAreas[index] = name;
                    
                    // Update tables that use this area
                    for (int i = 0; i < _tempTables.length; i++) {
                        if (_tempTables[i].area == oldName) {
                            _tempTables[i] = TableModel(
                                id: _tempTables[i].id, 
                                code: _tempTables[i].code,
                                name: _tempTables[i].name, 
                                area: name,
                                status: _tempTables[i].status,
                                orders: _tempTables[i].orders,
                                payments: _tempTables[i].payments,
                                activeSessionId: _tempTables[i].activeSessionId,
                                seatedAt: _tempTables[i].seatedAt,
                            );
                        }
                    }
                  } else {
                    _tempAreas.add(name);
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

  void _deleteArea(int index) {
    final areaName = _tempAreas[index];
    final hasTables = _tempTables.any((t) => t.area == areaName);

    if (hasTables) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu bölgede masalar var! Önce masaları silin veya bölgesini değiştirin.'), backgroundColor: AppTheme.pastelRed),
        );
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmek istediğinize emin misiniz?'),
        content: Text('$areaName adlı bölgeyi silmek üzeresiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelRed),
            onPressed: () {
              setState(() {
                _tempAreas.removeAt(index);
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
          title: const Text('Masa ve Bölge Yönetimi'),
          backgroundColor: AppTheme.surfaceLight,
          iconTheme: const IconThemeData(color: AppTheme.textDark),
          titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Masa Yönetimi'),
              Tab(text: 'Bölge Yönetimi'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _saveAll,
                icon: const Icon(Icons.save),
                label: const Text('Değişiklikleri Kaydet'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelMalachite, foregroundColor: Colors.white),
              ),
            )
          ],
        ),
        body: TabBarView(
          children: [
            _buildTablesTab(),
            _buildAreasTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'addTable',
                onPressed: () => _showTableDialog(),
                backgroundColor: AppTheme.pastelMalachite,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Yeni Masa', style: TextStyle(color: Colors.white)),
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
              controller: _tableScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _tableScrollController,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.primary.withOpacity(0.1)),
                    columns: const [
                      DataColumn(label: Text('Masa Kodu', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Masa Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Bölge', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _tempTables.asMap().entries.map((entry) {
                      final index = entry.key;
                      final table = entry.value;
                      final isOccupied = table.status == TableStatus.occupied || table.orders.isNotEmpty;
                      return DataRow(
                        cells: [
                          DataCell(Text(table.code)),
                          DataCell(Text(table.name)),
                          DataCell(Text(table.area)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                                  onPressed: () => _showTableDialog(table: table, index: index),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: isOccupied ? AppTheme.textMuted : AppTheme.pastelRed),
                                  onPressed: isOccupied ? null : () => _deleteTable(index),
                                  tooltip: isOccupied ? 'Dolu masa silinemez. Önce masayı kapatın.' : 'Sil',
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

  Widget _buildAreasTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'addArea',
                onPressed: () => _showAreaDialog(),
                backgroundColor: AppTheme.pastelMalachite,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Yeni Bölge', style: TextStyle(color: Colors.white)),
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
              controller: _areaScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _areaScrollController,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.primary.withOpacity(0.1)),
                    columns: const [
                      DataColumn(label: Text('Bölge Adı', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Masa Sayısı', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _tempAreas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final area = entry.value;
                      final count = _tempTables.where((t) => t.area == area).length;
                      return DataRow(
                        cells: [
                          DataCell(Text(area)),
                          DataCell(Text(count.toString())),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                                  onPressed: () => _showAreaDialog(area: area, index: index),
                                  tooltip: 'Düzenle',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.pastelRed),
                                  onPressed: () => _deleteArea(index),
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
