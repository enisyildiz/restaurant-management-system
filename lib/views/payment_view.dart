import 'package:flutter/material.dart';

import '../controllers/restaurant_controller.dart';
import '../models/payment_record.dart';
import '../theme/theme.dart';

class PaymentView extends StatefulWidget {
  final RestaurantController controller;
  final int tableId;

  const PaymentView({
    super.key,
    required this.controller,
    required this.tableId,
  });

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  String amountInput = '0';

  double get enteredAmount {
    final parsed = double.tryParse(amountInput);
    if (parsed == null || parsed <= 0) return 0;
    return parsed;
  }

  void _onNumpadPressed(String value) {
    setState(() {
      if (value == 'C') {
        amountInput = '0';
        return;
      }
      if (value == '⌫') {
        if (amountInput.length <= 1) {
          amountInput = '0';
        } else {
          amountInput = amountInput.substring(0, amountInput.length - 1);
        }
        return;
      }
      if (amountInput == '0') {
        if (value != '0') amountInput = value;
      } else {
        amountInput += value;
      }
      if (amountInput.length > 7) amountInput = amountInput.substring(0, 7);
    });
  }

  void _setAmount(double amount) {
    setState(() {
      amountInput = amount.toStringAsFixed(0);
    });
  }

  void _takePayment(PaymentMethod method) {
    if (enteredAmount <= 0) return;

    widget.controller.addPaymentToTable(
      tableId: widget.tableId,
      amount: enteredAmount,
      method: method,
    );

    final remaining = widget.controller.remainingForTable(widget.tableId);

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödeme tamamlandı. Masa tamamen ödendi!'),
          backgroundColor: AppTheme.pastelGreen,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      amountInput = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final remaining = widget.controller.remainingForTable(widget.tableId);
        final currentTotal = widget.controller.totalForTable(widget.tableId);
        final totalPaid = widget.controller.totalPaidForTable(widget.tableId);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text('Ödeme - Masa ${widget.tableId}'),
            backgroundColor: AppTheme.surfaceLight,
            elevation: 1,
            iconTheme: const IconThemeData(color: AppTheme.textDark),
            titleTextStyle: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Hesap Özeti',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 32),
                        _buildSummaryRow('Toplam Tutar', currentTotal, AppTheme.textDark, 20),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Alınan Ödeme', totalPaid, AppTheme.pastelGreen, 20),
                        const Divider(height: 48, thickness: 2),
                        _buildSummaryRow('Kalan Tutar', remaining, AppTheme.pastelRed, 28, isBold: true),
                        const SizedBox(height: 32),
                        const Text('Alınan Ödemeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: widget.controller.tables.firstWhere((t) => t.id == widget.tableId).payments.isEmpty
                              ? const Text('Henüz ödeme alınmadı.', style: TextStyle(color: AppTheme.textMuted))
                              : ListView.builder(
                                  itemCount: widget.controller.tables.firstWhere((t) => t.id == widget.tableId).payments.length,
                                  itemBuilder: (context, index) {
                                    final p = widget.controller.tables.firstWhere((t) => t.id == widget.tableId).payments[index];
                                    final isCash = p.method == PaymentMethod.cash;
                                    final isDiscount = p.method == PaymentMethod.discount;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        isDiscount ? Icons.discount : (isCash ? Icons.money : Icons.credit_card),
                                        color: isDiscount ? Colors.orange.shade300 : (isCash ? AppTheme.pastelGreen : AppTheme.pastelBlue)
                                      ),
                                      title: Text('${p.amount.toStringAsFixed(2)} ₺', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(isDiscount ? 'İndirim' : (isCash ? 'Nakit' : 'Kredi Kartı')),
                                    );
                                  },
                                ),
                        ),
                        if (widget.controller.currentUser?.role.name == 'admin') ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.discount, color: AppTheme.textDark),
                              label: const Text('İndirim Gir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade200,
                                foregroundColor: AppTheme.textDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                _showDiscountDialog(context);
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                        ),
                        child: Text(
                          '$amountInput ₺',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickAmountBtn(remaining * 0.25, '1/4'),
                          _buildQuickAmountBtn(remaining * 0.50, '1/2'),
                          _buildQuickAmountBtn(remaining, 'Tamamı'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildNumBtn('1')), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('2')), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('3')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildNumBtn('4')), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('5')), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('6')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildNumBtn('7')), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('8')), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('9')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildNumBtn('C', color: AppTheme.pastelRed)), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('0')), const SizedBox(width: 16),
                                  Expanded(child: _buildNumBtn('⌫', color: AppTheme.pastelRed)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn(
                              'Nakit',
                              Icons.money,
                              AppTheme.pastelGreen,
                              () => _takePayment(PaymentMethod.cash),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionBtn(
                              'Kredi Kartı',
                              Icons.credit_card,
                              AppTheme.pastelBlue,
                              () => _takePayment(PaymentMethod.creditCard),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color valueColor, double fontSize, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize * 0.8,
            color: AppTheme.textMuted,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} ₺',
          style: TextStyle(
            fontSize: fontSize,
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAmountBtn(double amount, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceLight,
            foregroundColor: AppTheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => _setAmount(amount),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildNumBtn(String value, {Color? color}) {
    final bgColor = color?.withOpacity(0.2) ?? AppTheme.surfaceLight;
    final fgColor = color ?? AppTheme.textDark;
    
    return InkWell(
      onTap: () => _onNumpadPressed(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppTheme.textDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    String discountInput = '0';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void onKeyPress(String key) {
              setStateDialog(() {
                if (key == 'C') {
                  discountInput = '0';
                } else if (key == '⌫') {
                  if (discountInput.length <= 1) {
                    discountInput = '0';
                  } else {
                    discountInput = discountInput.substring(0, discountInput.length - 1);
                  }
                } else {
                  if (discountInput == '0') {
                    if (key != '0') discountInput = key;
                  } else {
                    discountInput += key;
                  }
                }
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.surfaceLight,
              title: const Text('İndirim Gir'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$discountInput ₺',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.5,
                      children: [
                        for (var i = 1; i <= 9; i++)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.background, foregroundColor: AppTheme.textDark),
                            onPressed: () => onKeyPress(i.toString()),
                            child: Text(i.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelRed, foregroundColor: AppTheme.textDark),
                          onPressed: () => onKeyPress('C'),
                          child: const Text('C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.background, foregroundColor: AppTheme.textDark),
                          onPressed: () => onKeyPress('0'),
                          child: const Text('0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelRed, foregroundColor: AppTheme.textDark),
                          onPressed: () => onKeyPress('⌫'),
                          child: const Icon(Icons.backspace),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelGreen, foregroundColor: AppTheme.textDark),
                  onPressed: () {
                    final val = double.tryParse(discountInput) ?? 0;
                    if (val > 0) {
                      final table = widget.controller.tables.firstWhere((t) => t.id == widget.tableId);
                      final remaining = table.remainingAmount;

                      if (val > remaining) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hata: İndirim miktarı kalan tutardan fazla olamaz!'),
                            backgroundColor: AppTheme.pastelRed,
                          ),
                        );
                        return;
                      }

                      if (val == remaining) {
                        showDialog(
                          context: context,
                          builder: (context2) => AlertDialog(
                            title: const Text('Tüm Hesaba İndirim'),
                            content: const Text('Emin misiniz? Geri kalan tüm tutarı indirim olarak girdiğiniz için masa tamamen kapatılacaktır.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context2),
                                child: const Text('Hayır', style: TextStyle(color: AppTheme.textDark)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pastelGreen, foregroundColor: AppTheme.textDark),
                                onPressed: () {
                                  Navigator.pop(context2);
                                  Navigator.pop(context);
                                  widget.controller.addPaymentToTable(
                                    tableId: widget.tableId,
                                    amount: val,
                                    method: PaymentMethod.discount,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$val ₺ indirim uygulandı.'), backgroundColor: AppTheme.pastelGreen),
                                  );
                                },
                                child: const Text('Evet'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      widget.controller.addPaymentToTable(
                        tableId: widget.tableId,
                        amount: val,
                        method: PaymentMethod.discount,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$val ₺ indirim uygulandı.'), backgroundColor: AppTheme.pastelGreen),
                      );
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Uygula', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}