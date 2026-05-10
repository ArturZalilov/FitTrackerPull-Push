// 📁 lib/features/auth/ui/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ ДОБАВЛЕНО: для FirebaseAuthException
import '../auth_notifier.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    void showError(String message) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }

    bool validateLogin() {
      if (emailController.text.trim().isEmpty) {
        showError('Please enter your email');
        return false;
      }
      if (passwordController.text.trim().isEmpty) {
        showError('Please enter your password');
        return false;
      }
      return true;
    }

    void handleLogin() async {
      if (!validateLogin()) return;

      try {
        await ref
            .read(authNotifierProvider.notifier)
            .signIn(
              emailController.text.trim(),
              passwordController.text.trim(),
            );

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/app');
        }
      }
      // ✅ ДОБАВЛЕНО: обработка конкретных ошибок Firebase
      on FirebaseAuthException catch (e) {
        String message = 'Ошибка входа';

        switch (e.code) {
          case 'user-not-found':
            message = 'Пользователь с таким email не найден';
            break;
          case 'wrong-password':
            message = 'Неверный пароль';
            break;
          case 'invalid-email':
            message = 'Некорректный формат email';
            break;
          case 'user-disabled':
            message = 'Аккаунт заблокирован';
            break;
          case 'too-many-requests':
            message = 'Слишком много попыток. Попробуйте позже';
            break;
          case 'network-request-failed':
            message = 'Нет соединения с интернетом';
            break;
          case 'invalid-credential':
            message = 'Неверный email или пароль';
            break;
          default:
            message = 'Ошибка: ${e.message}';
        }

        if (context.mounted) {
          showError(message);
        }
      } catch (e) {
        // ✅ Обработка остальных ошибок
        if (context.mounted) {
          showError('Ошибка входа: ${e.toString()}');
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Login',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'Create account',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
