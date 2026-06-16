import 'package:flutter/material.dart';
import 'controllers/restaurant_controller.dart';
import 'views/main_menu_view.dart';
import 'globals.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final restaurantController = RestaurantController();

  runApp(RestaurantManagerApp(controller: restaurantController));
}

class RestaurantManagerApp extends StatelessWidget {
  final RestaurantController controller;

  const RestaurantManagerApp({Key? key, required this.controller}) : super(key: key);

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
      home: MainMenuView(controller: controller),
    );
  }
}