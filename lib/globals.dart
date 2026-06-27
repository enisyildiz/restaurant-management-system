import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Bu IP adresini Admin bilgisayarının yerel ağdaki IP adresi ile değiştirin.
// Örnek: '192.168.1.50'
String serverIp = '127.0.0.1';