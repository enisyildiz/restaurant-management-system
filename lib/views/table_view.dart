import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/table_model.dart';
import '../models/user_role.dart';
import '../theme/theme.dart';
import 'order_view.dart';
import 'login_view.dart';

class TableView extends StatelessWidget {
  final RestaurantController controller;

  const TableView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final List<String> areas = ['Tümü'];
        areas.addAll(controller.tables.map((t) => t.area).toSet());

        if (controller.tables.isEmpty) {
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
                if (controller.currentUser?.role == UserRole.waiter)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      controller.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LoginView(controller: controller)),
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
                    ? controller.tables
                    : controller.tables.where((t) => t.area == area).toList();

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
                            statusText =
                                '${table.currentTotal.toStringAsFixed(2)} ₺';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderView(
                                    controller: controller,
                                    tableId: table.id,
                                  ),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 140,
                              height: 90,
                              decoration: BoxDecoration(
                                color: bgColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: bgColor.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    table.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    statusText,
                                    style: const TextStyle(
                                      fontSize: 16,
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
