import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkAuthAndNavigate();
  }

  Future<void> checkAuthAndNavigate() async {
    // 1️⃣ Ждём 2 секунды, чтобы пользователь увидел логотип
    await Future.delayed(const Duration(seconds: 2));

    // 2️⃣ Проверяем, не удалён ли виджет за время ожидания
    if (!mounted) return;

    // 3️⃣ Читаем текущее состояние авторизации из Riverpod
    final authState = ref.read(authStateProvider);

    // 4️⃣ Принимаем решение о переходе
    authState.when(
      data: (user) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            user != null ? '/app' : '/login',
          );
        }
      },
      loading: () {
        // Если Firebase ещё не ответил за 2 сек → идём на логин
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      },
      error: (_, __) {
        // Ошибка сети или авторизации → на логин
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FitTrack',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
