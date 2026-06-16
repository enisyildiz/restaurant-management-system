import 'package:flutter/material.dart';

import '../models/restaurant_table.dart';
import '../models/table_status.dart';

//connects the table status to the color
class TableTile extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const TableTile({
    super.key,
    required this.table,
    required this.onTap,
  });

  Color get tableColor {
    switch (table.status) {
      case TableStatus.empty:
        return Colors.white;
      case TableStatus.occupied:
        return Colors.yellow;
      case TableStatus.askedForCheck:
        return Colors.red;
    }
  }

  Color get textColor {
    switch (table.status) {
      case TableStatus.empty:
      case TableStatus.occupied:
        return Colors.black;
      case TableStatus.askedForCheck:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 92,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tableColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black54),
        ),
        child: Text(
          table.code,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}