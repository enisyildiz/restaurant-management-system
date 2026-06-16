import 'package:flutter/material.dart';

import '../controllers/restaurant_controller.dart';
import '../models/order_item.dart';
import '../models/payment_record.dart';

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

    if (parsed == null || parsed <= 0) {
      return 0;
    }

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
        amountInput = value;
      } else {
        amountInput += value;
      }

      if (amountInput.length > 7) {
        amountInput = amountInput.substring(0, 7);
      }
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
          content: Text('Payment completed. Table cleared.'),
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
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
        final orders = widget.controller.ordersForTable(widget.tableId);
        final payments = widget.controller.paymentsForTable(widget.tableId);
        final total = widget.controller.totalForTable(widget.tableId);
        final paid = widget.controller.totalPaidForTable(widget.tableId);
        final remaining = widget.controller.remainingForTable(widget.tableId);
        final cashPaid = widget.controller.cashPaidForTable(widget.tableId);
        final cardPaid =
            widget.controller.creditCardPaidForTable(widget.tableId);

        return Scaffold(
          appBar: AppBar(
            title: Text('Payment - Table ${widget.tableId}'),
          ),
          body: Row(
            children: [
              Expanded(
                flex: 4,
                child: _PaymentBillPanel(
                  orders: orders,
                  payments: payments,
                  total: total,
                  paid: paid,
                  remaining: remaining,
                  cashPaid: cashPaid,
                  cardPaid: cardPaid,
                ),
              ),

              const VerticalDivider(width: 1),

              Expanded(
                flex: 4,
                child: _PaymentAmountPanel(
                  amountInput: amountInput,
                  remaining: remaining,
                  onNumpadPressed: _onNumpadPressed,
                  onShortcutPressed: _setAmount,
                ),
              ),

              const VerticalDivider(width: 1),

              Expanded(
                flex: 2,
                child: _PaymentMethodPanel(
                  enteredAmount: enteredAmount,
                  remaining: remaining,
                  onCashPressed: () => _takePayment(PaymentMethod.cash),
                  onCardPressed: () => _takePayment(PaymentMethod.creditCard),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentBillPanel extends StatelessWidget {
  final List<OrderItem> orders;
  final List<PaymentRecord> payments;
  final double total;
  final double paid;
  final double remaining;
  final double cashPaid;
  final double cardPaid;

  const _PaymentBillPanel({
    required this.orders,
    required this.payments,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.cashPaid,
    required this.cardPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
  child: ListView(
    children: [
      const Text(
        'Orders',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 6),

      for (final item in orders)
        Card(
          child: ListTile(
            title: Text(item.product.name),
            subtitle: Text(
              '${item.quantity} x ${item.product.price.toStringAsFixed(2)}',
            ),
            trailing: Text(
              item.totalPrice.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

      if (payments.isNotEmpty) ...[
        const SizedBox(height: 16),

        const Text(
          'Payment History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        for (final payment in payments)
          Card(
            child: ListTile(
              leading: Icon(
                payment.method == PaymentMethod.cash
                    ? Icons.payments
                    : Icons.credit_card,
              ),
              title: Text(payment.method.label),
              trailing: Text(
                payment.amount.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ],
  ),
),

          const Divider(),

          _TotalRow(label: 'Total', value: total),
          _TotalRow(label: 'Paid', value: paid),
          _TotalRow(label: 'Remaining', value: remaining, isImportant: true),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _PaymentSummaryCard(
                  title: 'Cash',
                  amount: cashPaid,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PaymentSummaryCard(
                  title: 'Credit Card',
                  amount: cardPaid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentAmountPanel extends StatelessWidget {
  final String amountInput;
  final double remaining;
  final void Function(String value) onNumpadPressed;
  final void Function(double amount) onShortcutPressed;

  const _PaymentAmountPanel({
    required this.amountInput,
    required this.remaining,
    required this.onNumpadPressed,
    required this.onShortcutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final half = remaining / 2;
    final quarter = remaining / 4;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Payment Amount',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              amountInput,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: remaining <= 0
                      ? null
                      : () => onShortcutPressed(quarter),
                  child: const Text('1/4'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed:
                      remaining <= 0 ? null : () => onShortcutPressed(half),
                  child: const Text('1/2'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: remaining <= 0
                      ? null
                      : () => onShortcutPressed(remaining),
                  child: const Text('Full'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _PaymentNumpad(
              onPressed: onNumpadPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodPanel extends StatelessWidget {
  final double enteredAmount;
  final double remaining;
  final VoidCallback onCashPressed;
  final VoidCallback onCardPressed;

  const _PaymentMethodPanel({
    required this.enteredAmount,
    required this.remaining,
    required this.onCashPressed,
    required this.onCardPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canPay = enteredAmount > 0 && remaining > 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Payment Type',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canPay ? onCashPressed : null,
                      icon: const Icon(Icons.payments),
                      label: const Text(
                        'Cash',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: canPay ? onCardPressed : null,
                      icon: const Icon(Icons.credit_card),
                      label: const Text(
                        'Credit Card',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentNumpad extends StatelessWidget {
  final void Function(String value) onPressed;

  const _PaymentNumpad({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Row(
            children: row.map((value) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FilledButton.tonal(
                    onPressed: () => onPressed(value),
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isImportant;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isImportant = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: isImportant ? 22 : 18,
              fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: isImportant ? 22 : 18,
              fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final String title;
  final double amount;

  const _PaymentSummaryCard({
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}