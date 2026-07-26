import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class NumpadWidget extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const NumpadWidget({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  void _onKeyPress(String key) {
    if (key == 'C') {
      onChanged('0');
      return;
    }

    if (key == '<') {
      if (value.length > 1) {
        onChanged(value.substring(0, value.length - 1));
      } else {
        onChanged('0');
      }
      return;
    }

    if (key == '.') {
      if (!value.contains('.')) {
        onChanged(value + '.');
      }
      return;
    }

    if (value == '0') {
      onChanged(key);
    } else {
      // Limit length to avoid huge numbers
      if (value.length < 8) {
        onChanged(value + key);
      }
    }
  }

  Widget _buildKey(String key, {Color? bgColor, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: bgColor ?? AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _onKeyPress(key),
            child: SizedBox(
              height: 46, // Reduced fixed height for a more compact numpad
              child: Center(
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? AppTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          Row(
            children: [
              _buildKey('C', bgColor: AppTheme.pastelRed, textColor: Colors.white),
              _buildKey('0'),
              _buildKey('.'),
              _buildKey('<', bgColor: AppTheme.pastelOrange, textColor: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
