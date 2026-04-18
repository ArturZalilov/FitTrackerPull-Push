// 📁 lib/features/auth/ui/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  // ✅ Stateful вместо Widget
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // ✅ Контроллеры создаём один раз при инициализации
  late final TextEditingController _nameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    // ✅ Инициализация контроллеров
    _nameController = TextEditingController();
    _lastNameController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ Очищаем контроллеры
    _nameController.dispose();
    _lastNameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void handleRegister() async {
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
            _lastNameController.text.trim(),
            _weightController.text.trim(),
            _heightController.text.trim(),
          );

      // ✅ Правильно: используем mounted (без context.)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/app');
      }
    } catch (e) {
      // ✅ Тоже используем mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getAuthErrorMessage(e)),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  String _getAuthErrorMessage(dynamic error) {
    String code = error?.code?.toString() ?? '';

    switch (code) {
      case 'email-already-in-use':
        return '📧 Этот email уже зарегистрирован. Попробуйте войти.';
      case 'invalid-email':
        return '❌ Некорректный email адрес.';
      case 'weak-password':
        return '🔒 Пароль слишком слабый (минимум 6 символов).';
      case 'operation-not-allowed':
        return '⚠️ Регистрация временно недоступна.';
      case 'network-request-failed':
        return '🌐 Проверьте подключение к интернету.';
      default:
        return '⚠️ ${error?.toString() ?? "Неизвестная ошибка"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // ✅ Имя
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.text, // ✅ Явно разрешаем буквы
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Фамилия
                TextField(
                  controller: _lastNameController,
                  keyboardType: TextInputType.text, // ✅ Явно разрешаем буквы
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Your last name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Вес (только цифры)
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 75',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Рост (только цифры)
                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'e.g. 180',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Пароль
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••',
                    border: OutlineInputBorder(),
                  ),
                ),

                ElevatedButton(
                  onPressed: handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
