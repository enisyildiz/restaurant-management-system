import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../models/user_role.dart';
import '../theme/theme.dart';
import 'order_view.dart';
import 'login_view.dart';

class TableView extends StatefulWidget {
  final RestaurantController controller;

  const TableView({Key? key, required this.controller}) : super(key: key);

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  double _tableScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final List<String> areas = ['Tümü'];
        areas.addAll(widget.controller.tables.map((t) => t.area).toSet());

        if (widget.controller.tables.isEmpty) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return DefaultTabController(
          length: areas.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Masalar'),
              bottom: TabBar(
                isScrollable: true,
                tabs: areas.map((a) => Tab(text: a.toUpperCase())).toList(),
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              actions: [
                SizedBox(
                  width: 150,
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, size: 20, color: AppTheme.primary),
                      Expanded(
                        child: Slider(
                          value: _tableScale,
                          min: 0.5,
                          max: 2.0,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            setState(() {
                              _tableScale = val;
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.zoom_in, size: 20, color: AppTheme.primary),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.controller.currentUser?.role == UserRole.waiter)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      widget.controller.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LoginView(controller: widget.controller)),
                      );
                    },
                    tooltip: 'Çıkış Yap',
                  ),
                const SizedBox(width: 16),
              ],
            ),
            body: TabBarView(
              children: areas.map((area) {
                final areaTables = area == 'Tümü'
                    ? widget.controller.tables
                    : widget.controller.tables.where((t) => t.area == area).toList();

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.start,
                        children: areaTables.map((table) {
                          final isEmpty = table.status == TableStatus.empty;

                          Color bgColor;
                          Color borderColor;
                          String statusText;

                          if (isEmpty) {
                            bgColor = AppTheme.pastelGreen;
                            borderColor = AppTheme.pastelGreen;
                            statusText = 'BOŞ';
                          } else {
                            bgColor = AppTheme.pastelOrange;
                            borderColor = AppTheme.pastelOrange;
                            statusText = 'DOLU';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderView(
                                    controller: widget.controller,
                                    tableId: table.id,
                                  ),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 140 * _tableScale,
                              height: 90 * _tableScale,
                              decoration: BoxDecoration(
                                color: bgColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16 * _tableScale),
                                border: Border.all(
                                  color: borderColor.withOpacity(0.5),
                                  width: 2 * _tableScale,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: bgColor.withOpacity(0.1),
                                    blurRadius: 15 * _tableScale,
                                    offset: Offset(0, 8 * _tableScale),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    table.name,
                                    style: TextStyle(
                                      fontSize: 20 * _tableScale,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 6 * _tableScale),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 16 * _tableScale,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
