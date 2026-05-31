import 'package:flutter/material.dart';
import 'controllers/restaurant_controller.dart';
import 'views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Controller uygulamanın en başında bir kez oluşturulur.
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
      debugShowCheckedModeBanner: false, // Sağ üstteki debug yazısını kaldırır
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // Modern bir görünüm için
      ),
      // Controller'ı ana ekrana enjekte ediyoruz (Dependency Injection mantığı)
      home: HomeView(controller: controller),
    );
  }
}