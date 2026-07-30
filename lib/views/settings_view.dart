import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../theme/theme.dart';
import 'widgets/user_management_page.dart';

class SettingsView extends StatefulWidget {
  final RestaurantController controller;

  const SettingsView({super.key, required this.controller});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppTheme.surfaceLight,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: AppTheme.surfaceLight,
            selectedIconTheme: const IconThemeData(color: AppTheme.primary),
            unselectedIconTheme: IconThemeData(color: AppTheme.textMuted.withOpacity(0.5)),
            selectedLabelTextStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.8)),
            
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Personel Yönetimi'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Ana İçerik Alanı
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return UserManagementPage(controller: widget.controller);
      default:
        return const Center(child: Text('Sayfa bulunamadı'));
    }
  }
}
