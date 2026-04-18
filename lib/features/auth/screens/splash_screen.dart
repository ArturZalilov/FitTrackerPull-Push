// 📁 lib/features/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _canNavigate = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _canNavigate = true;
        });
        _tryNavigate();
      }
    });
  }

  void _tryNavigate() {
    if (!_canNavigate || !mounted) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) {
        if (mounted) {
          debugPrint('🔑 Auth resolved: ${user?.email ?? "null"}');
          Navigator.pushReplacementNamed(
            context,
            user != null ? '/app' : '/login',
          );
        }
      },
      loading: () {
        debugPrint('⏳ Firebase ещё проверяет токен...');
      },
      error: (err, stack) {
        if (mounted) {
          debugPrint('❌ Auth error: $err');
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Только BuildContext, без ref!
    // 🔥 Слушаем authState
    ref.listen(authStateProvider, (previous, next) {
      if (_canNavigate) {
        _tryNavigate();
      }
    });

    // 🎨 Твой красивый UI
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
