import 'package:flutter/material.dart';
import 'package:core/views/home_view.dart';
import 'package:core/controllers/restaurant_controller.dart';

class MainMenuScreen extends StatelessWidget {
  final RestaurantController controller;

  const MainMenuScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Order App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _MainMenuCard(
                icon: Icons.table_restaurant,
                title: 'Tables',
                subtitle: 'Open table order screen',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeView(controller: controller),
                    ),
                  );
                },
              ),

              const _MainMenuCard(
                icon: Icons.account_balance_wallet,
                title: 'Vault',
                subtitle: 'Coming soon',
                onTap: null,
              ),

              const _MainMenuCard(
                icon: Icons.bar_chart,
                title: 'Today\'s Sales',
                subtitle: 'Coming soon',
                onTap: null,
              ),

              const _MainMenuCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Coming soon',
                onTap: null,
              ),
            ],
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
  final VoidCallback? onTap;

  const _MainMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.45,
        child: Container(
          width: 240,
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}