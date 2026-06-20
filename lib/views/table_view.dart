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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masalar'),
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
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.1,
              ),
              itemCount: controller.tables.length,
              itemBuilder: (context, index) {
                final table = controller.tables[index];
                final isEmpty = table.status == TableStatus.empty;
                final isFullyPaid = !isEmpty && controller.remainingForTable(table.id) <= 0;

                Color bgColor;
                Color borderColor;
                String statusText;

                if (isEmpty) {
                  bgColor = AppTheme.pastelGreen;
                  borderColor = AppTheme.pastelGreen;
                  statusText = 'BOŞ';
                } else if (isFullyPaid) {
                  bgColor = AppTheme.pastelYellow;
                  borderColor = AppTheme.pastelYellow;
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEmpty ? Icons.check_circle_outline : (isFullyPaid ? Icons.money : Icons.restaurant),
                            color: bgColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          table.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14,
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
        },
      ),
    );
  }
}