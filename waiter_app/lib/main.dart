import 'package:flutter/material.dart';
import 'package:core/views/home_view.dart';
import 'package:core/globals.dart';
import 'package:core/controllers/restaurant_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final restaurantController = RestaurantController();

  runApp(RestaurantApp(controller: restaurantController));
}

class RestaurantApp extends StatelessWidget {
  final RestaurantController controller;

  const RestaurantApp({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restoran Demo',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: globalMessengerKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: HomeView(controller: controller),
    );
  }
}