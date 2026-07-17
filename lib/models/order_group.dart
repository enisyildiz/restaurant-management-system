import 'package:uuid/uuid.dart';
import 'order_item.dart';

class OrderGroup {
  final String id;
  final DateTime createdAt;
  bool isPrintedToKitchen;
  List<OrderItem> items;

  OrderGroup({
    String? id,
    DateTime? createdAt,
    this.isPrintedToKitchen = false,
    List<OrderItem>? items,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        items = items ?? [];

  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'isPrintedToKitchen': isPrintedToKitchen,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  factory OrderGroup.fromJson(Map<String, dynamic> json) {
    return OrderGroup(
      id: json['id'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      isPrintedToKitchen: json['isPrintedToKitchen'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((itemJson) => OrderItem.fromJson(itemJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
