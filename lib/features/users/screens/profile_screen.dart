// 📁 lib/features/users/ui/profile_screen.dart
import 'package:fit_tracker_pull_and_push/features/users/user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Добавили
import '../../auth/auth_notifier.dart'; // ✅ Путь к твоему auth_notifier

class ProfileScreen extends ConsumerWidget {
  // ✅ ConsumerWidget
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userNotifierProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Профиль'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF3B82F6),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            userData.when(
              data: (userProfile) => Text(
                // ✅ Обращаемся к свойству name
                userProfile.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 8),
            userData.when(
              data: (userProfile) => Text(
                // ✅ Обращаемся к свойству lastName
                userProfile.lastName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 32),
            userData.when(
              data: (userProfile) => Text(
                // ✅ Обращаемся к свойству weight
                userProfile.weight,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 32),
            userData.when(
              data: (userProfile) => Text(
                // ✅ Обращаемся к свойству height
                userProfile.height,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Total Workouts'),
                    trailing: const Text(
                      '24',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    // ✅ ИСПРАВЛЕНИЕ: реальный выход через Riverpod
                    onTap: () async {
                      // 1. Вызываем signOut из AuthNotifier
                      await ref.read(authNotifierProvider.notifier).signOut();

                      // 2. Только после успешного выхода — навигация
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
