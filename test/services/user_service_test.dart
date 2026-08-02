import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:restaurant_management_app/services/user_service.dart';
import 'package:restaurant_management_app/models/user_role.dart';

// Fake PathProvider for testing file writing without launching emulator
class FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path; // Write users.json to temp dir for tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    PathProviderPlatform.instance = FakePathProvider();
  });

  group('UserService JSON Integration Tests', () {
    setUp(() async {
      // Her testten önce listeyi temizle ve dosyayı boşalt
      final file = File('${Directory.systemTemp.path}/KarPos/users.json');
      if (file.existsSync()) {
        file.deleteSync();
      }
      UserService.instance.users.clear();
    });

    test('Loads empty users list initially', () async {
      await UserService.instance.loadUsers();
      expect(UserService.instance.users, isEmpty);
    });

    test('Can add a user and save it to file', () async {
      final newUser = LocalUser(username: 'test_garson', password: '123', role: UserRole.waiter);
      
      // Limit 5 olsun, 1 tane ekliyoruz
      await UserService.instance.addUser(newUser, 5);
      
      expect(UserService.instance.users.length, 1);
      expect(UserService.instance.users.first.username, 'test_garson');
      
      // Şimdi RAM'den değil, dosyadan tekrar yükleyip kontrol edelim
      UserService.instance.users.clear();
      await UserService.instance.loadUsers();
      
      expect(UserService.instance.users.length, 1);
      expect(UserService.instance.users.first.password, '123');
    });

    test('Enforces maxTablets limit from Firebase', () async {
      final user1 = LocalUser(username: 'g1', password: '1', role: UserRole.waiter);
      final user2 = LocalUser(username: 'g2', password: '2', role: UserRole.waiter);
      
      // Firebase'den maxTablets = 1 geldiğini varsayalım
      await UserService.instance.addUser(user1, 1);
      
      // 2. garsonu eklerken Exception fırlatmalı
      expect(
        () => UserService.instance.addUser(user2, 1),
        throwsException,
      );
    });

    test('Authenticates user correctly', () async {
      final user = LocalUser(username: 'ahmet', password: '456', role: UserRole.waiter);
      await UserService.instance.addUser(user, 5);
      
      final authResult = UserService.instance.authenticate('ahmet', '456');
      expect(authResult, isNotNull);
      expect(authResult!.username, 'ahmet');
      
      final failResult = UserService.instance.authenticate('ahmet', 'yanlis');
      expect(failResult, isNull);
    });
  });
}
