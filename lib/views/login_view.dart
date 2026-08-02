import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import '../controllers/restaurant_controller.dart';
import '../models/user_role.dart';
import 'main_menu_view.dart';
import 'table_view.dart';
import '../theme/theme.dart';

class LoginView extends StatefulWidget {
  final RestaurantController controller;

  const LoginView({super.key, required this.controller});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate a brief network delay for UX
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final success = await widget.controller.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        if (!mounted) return;
        final role = widget.controller.currentUser!.role;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              if (role == UserRole.waiter) {
                return TableView(controller: widget.controller);
              }
              return MainMenuView(controller: widget.controller);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Geçersiz e-posta/kullanıcı adı veya şifre';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceAll('LicenseException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.2),
              AppTheme.primaryDark.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 280, // Adjust this as needed, it will scale proportionately
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.pastelRed.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.pastelRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style:
                                    const TextStyle(color: AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildTextField(
                      controller: _usernameController,
                      hintText: 'Kullanıcı Adı',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Şifre',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'GİRİŞ YAP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.keyboard, size: 24),
                        label: const Text(
                          'EKRAN KLAVYESİ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceLight,
                          foregroundColor: AppTheme.primaryDark,
                          elevation: 0,
                          side: BorderSide(
                              color: AppTheme.primaryDark.withOpacity(0.5),
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Process.run('cmd.exe', ['/c', 'start', 'osk']);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.power_settings_new, size: 24),
                        label: const Text(
                          'UYGULAMAYI KAPAT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceLight,
                          foregroundColor: AppTheme.pastelRed, // Kırmızımsı ton
                          elevation: 0,
                          side: BorderSide(
                              color: AppTheme.pastelRed.withOpacity(0.5),
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          exit(0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppTheme.textDark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppTheme.textMuted),
          prefixIcon: Icon(icon, color: AppTheme.primaryDark),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
