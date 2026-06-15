import 'table_status.dart';

class RestaurantTable {
  final String code;
  final String area;
  TableStatus status;

  RestaurantTable({
    required this.code,
    required this.area,
    required this.status,
  });
}