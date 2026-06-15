import 'package:flutter/material.dart';

import '../models/restaurant_table.dart';
import 'table_tile.dart';

class AreaSection extends StatelessWidget {
  final String title;
  final List<RestaurantTable> tables;
  final void Function(RestaurantTable table) onTableTap;

  const AreaSection({
    super.key,
    required this.title,
    required this.tables,
    required this.onTableTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: tables.map((table) {
            return TableTile(
              table: table,
              onTap: () => onTableTap(table),
            );
          }).toList(),
        ),
      ],
    );
  }
}