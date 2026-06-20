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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              actions: [
                if (controller.currentUser?.role == UserRole.waiter)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      controller.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginView(controller: controller)),
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
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: areaTables.length,
                    itemBuilder: (context, index) {
                      final table = areaTables[index];
                      final isEmpty = table.status == TableStatus.empty;
                      final isFullyPaid = !isEmpty && controller.remainingForTable(table.id) <= 0;

                      final isPartiallyPaid = !isEmpty && table.totalPaid > 0 && controller.remainingForTable(table.id) > 0;

                      Color bgColor;
                      Color borderColor;
                      String statusText;

                      if (isEmpty) {
                        bgColor = AppTheme.pastelGreen;
                        borderColor = AppTheme.pastelGreen;
                        statusText = 'BOŞ';
                      } else if (isPartiallyPaid) {
                        bgColor = AppTheme.pastelOrange;
                        borderColor = AppTheme.pastelOrange;
                        statusText = 'Kısmi Ödendi\n${controller.remainingForTable(table.id).toStringAsFixed(2)} ₺';
                      } else if (isFullyPaid) {
                        bgColor = AppTheme.pastelOrange;
                        borderColor = AppTheme.pastelOrange;
                        statusText = 'ÖDENDİ';
                      } else {
                        bgColor = AppTheme.pastelRed;
                        borderColor = AppTheme.pastelRed;
                        statusText = '${table.currentTotal.toStringAsFixed(2)} ₺';
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
                          decoration: BoxDecoration(
                            color: bgColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
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
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: bgColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  table.code,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: bgColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                table.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: bgColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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