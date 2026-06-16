import 'package:flutter/material.dart';

class StatusLegend extends StatelessWidget {
  const StatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LegendItem(color: Colors.white, label: 'Empty', hasBorder: true),
        SizedBox(width: 18),
        LegendItem(color: Colors.yellow, label: 'Occupied'),
        SizedBox(width: 18),
        LegendItem(color: Colors.red, label: 'Asked for Check'),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool hasBorder;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            border: hasBorder ? Border.all(color: Colors.black54) : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}