import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/user_role.dart';

class LocalUser {
  final String username;
  final String password;
  final UserRole role;

  LocalUser({required this.username, required this.password, required this.role});

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'role': role.name,
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
    username: json['username'],
    password: json['password'],
    role: UserRole.values.firstWhere((e) => e.name == json['role'], orElse: () => UserRole.waiter),
  );
}

class UserService {
  static final UserService instance = UserService._init();
  UserService._init();

  List<LocalUser> _users = [];
  
  List<LocalUser> get users => _users;

  Future<File> get _file async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String path = p.join(appDocDir.path, 'RestaurantApp', 'users.json');
    return File(path);
  }

  Future<void> loadUsers() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> data = json.decode(contents);
        _users = data.map((e) => LocalUser.fromJson(e)).toList();
      } else {
        // İlk kullanımda varsayılan kasa hesabı yok, çünkü kasa artık Firebase ile girecek!
        // Ama test amaçlı veya acil durumlar için bir tablet eklenebilir.
        _users = [];
      }
    } catch (e) {
      _users = [];
    }
  }

  Future<void> saveUsers() async {
    final file = await _file;
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(json.encode(_users.map((e) => e.toJson()).toList()));
  }

  Future<bool> addUser(LocalUser user, int maxTablets) async {
    if (_users.any((u) => u.username == user.username)) {
      throw Exception('Bu kullanıcı adı zaten mevcut.');
    }
    
    // Sadece garson hesapları sayıya dahil edilir (Admin zaten Firebase ile girer)
    final waiterCount = _users.where((u) => u.role == UserRole.waiter).length;
    if (user.role == UserRole.waiter && waiterCount >= maxTablets) {
      throw Exception('Lisansınız maksimum $maxTablets garson tableti destekliyor.');
    }

    _users.add(user);
    await saveUsers();
    return true;
  }

  Future<void> removeUser(String username) async {
    _users.removeWhere((u) => u.username == username);
    await saveUsers();
  }

  LocalUser? authenticate(String username, String password) {
    try {
      return _users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}
