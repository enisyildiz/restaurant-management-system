import 'package:flutter/material.dart';
import 'table_view.dart';
import 'admin_dashboard_view.dart';
import 'menu_management_view.dart';
import 'table_management_view.dart';
import 'login_view.dart';
import '/controllers/restaurant_controller.dart';
import '../theme/theme.dart';
import 'cash_register_view.dart';

class MainMenuView extends StatelessWidget {
  final RestaurantController controller;

  const MainMenuView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isAdmin = controller.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoran Yönetimi'),
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MainMenuCard(
                    icon: Icons.table_restaurant,
                    title: 'Masalar',
                    subtitle: 'Sipariş ekranını aç',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TableView(controller: controller),
                        ),
                      );
                    },
                  ),
                ),

                if (isAdmin) const SizedBox(width: 16),
                if (isAdmin)
                  Expanded(
                    child: _MainMenuCard(
                      icon: Icons.bar_chart,
                      title: 'Yönetici Paneli',
                      subtitle: 'Satışları ve grafikleri gör',
                      color: AppTheme.pastelGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminDashboardView(controller: controller),
                          ),
                        );
                      },
                    ),
                  ),

                if (isAdmin) const SizedBox(width: 16),
                if (isAdmin)
                  Expanded(
                    child: _MainMenuCard(
                      icon: Icons.restaurant_menu,
                      title: 'Menü',
                      subtitle: 'Ürünleri yönet',
                      color: AppTheme.pastelOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuManagementView(controller: controller),
                          ),
                        );
                      },
                    ),
                  ),

                if (isAdmin) const SizedBox(width: 16),
                if (isAdmin)
                  Expanded(
                    child: _MainMenuCard(
                      icon: Icons.settings,
                      title: 'Ayarlar',
                      subtitle: 'Restoranını Yönet',
                      color: AppTheme.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TableManagementView(controller: controller),
                          ),
                        );
                      },
                    ),
                  ),

                if (isAdmin) const SizedBox(width: 16),
                if (isAdmin)
                  Expanded(
                    child: _MainMenuCard(
                      icon: Icons.account_balance_wallet,
                      title: 'Kasa',
                      subtitle: 'Gider hareketleri ve rapor',
                      color: AppTheme.pastelYellow,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CashRegisterView(controller: controller),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _MainMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.textMuted.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              if (isEnabled)
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}