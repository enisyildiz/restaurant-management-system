import 'package:flutter/material.dart';
import '../../controllers/restaurant_controller.dart';
import '../../services/user_service.dart';
import '../../models/user_role.dart';
import '../../theme/theme.dart';

class UserManagementPage extends StatefulWidget {
  final RestaurantController controller;

  const UserManagementPage({super.key, required this.controller});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load users if empty
    if (UserService.instance.users.isEmpty) {
      UserService.instance.loadUsers().then((_) => setState(() {}));
    }
  }

  void _addUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı adı ve şifre boş olamaz.')),
      );
      return;
    }

    try {
      final newUser = LocalUser(
        username: username,
        password: password,
        role: UserRole.waiter,
      );

      await UserService.instance.addUser(newUser, widget.controller.maxTablets);
      
      _usernameController.clear();
      _passwordController.clear();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personel başarıyla eklendi.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeUser(String username) async {
    await UserService.instance.removeUser(username);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personel silindi.')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final waiters = UserService.instance.users.where((u) => u.role == UserRole.waiter).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personel (Tablet) Yönetimi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Mevcut Lisansınızın İzin Verdiği Maksimum Tablet Sayısı: ${widget.controller.maxTablets}',
            style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(Icons.add),
                label: const Text('Personel Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Kayıtlı Personeller',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: waiters.isEmpty
                ? const Center(child: Text('Henüz personel eklenmedi.'))
                : ListView.builder(
                    itemCount: waiters.length,
                    itemBuilder: (context, index) {
                      final user = waiters[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: AppTheme.primary),
                          title: Text(user.username),
                          subtitle: const Text('Yetki: Garson (Tablet)'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeUser(user.username),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
