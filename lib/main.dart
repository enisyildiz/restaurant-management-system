import 'package:flutter/material.dart';
import 'controllers/restaurant_controller.dart';
import 'views/login_view.dart';
import 'globals.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String configPath = p.join(appDocDir.path, 'RestaurantApp', 'config.json');
    final File configFile = File(configPath);
    
    if (await configFile.exists()) {
      final String contents = await configFile.readAsString();
      final data = jsonDecode(contents);
      if (data['serverIp'] != null) {
        serverIp = data['serverIp'];
      }
    } else {
      final Directory appDocDirFolder = Directory(p.dirname(configPath));
      if (!await appDocDirFolder.exists()) {
        await appDocDirFolder.create(recursive: true);
      }
      
      final Map<String, dynamic> defaultConfig = {
        'serverIp': '127.0.0.1'
      };
      await configFile.writeAsString(jsonEncode(defaultConfig));
    }
  } catch (e) {
    debugPrint('Config file reading error: $e');
  }

  final restaurantController = RestaurantController();

  runApp(RestaurantManagerApp(controller: restaurantController));
}

class RestaurantManagerApp extends StatelessWidget {
  final RestaurantController controller;

  const RestaurantManagerApp({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant App',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: globalMessengerKey,
      theme: AppTheme.lightTheme,
      home: LoginView(controller: controller),
    );
  }
}