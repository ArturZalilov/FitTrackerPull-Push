// 📁 lib/features/users/ui/profile_screen.dart
import 'package:fit_tracker_pull_and_push/features/users/user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_notifier.dart';
import '../../workouts/workouts_notifier.dart'; // ✅ Добавили импорт тренировок

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userNotifierProvider);

    // ✅ Получаем ID пользователя и слушаем его тренировки
    final userId = ref.read(authRepositoryProvider).currentUserId;
    final workoutsAsync = userId != null
        ? ref.watch(userWorkoutsProvider(userId))
        : const AsyncValue.data([]);

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

            // Имя
            userData.when(
              data: (userProfile) => Text(
                userProfile.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 8),

            // Фамилия
            userData.when(
              data: (userProfile) => Text(
                userProfile.lastName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 32),

            // Вес
            userData.when(
              data: (userProfile) => Text(
                'Вес: ${userProfile.weight} кг',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 32),

            // Рост
            userData.when(
              data: (userProfile) => Text(
                'Рост: ${userProfile.height} см',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('Ошибка загрузки'),
            ),
            const SizedBox(height: 32),

            // ✅ Карточка со статистикой — РЕАЛЬНОЕ кол-во тренировок
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Total Workouts'),
                    trailing: workoutsAsync.when(
                      data: (workouts) => Text(
                        '${workouts.length}', // ✅ Реальное число тренировок
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => const Text(
                        '0',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка выхода
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
                    onTap: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
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
