// 📁 lib/features/workouts/screens/workouts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../workouts_notifier.dart';
import 'workout_detail_screen.dart'; // ✅ Импортируем унифицированный экран
import '../../auth/auth_notifier.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final workoutDate = DateTime(date.year, date.month, date.day);
    if (workoutDate == now) return 'Today';
    if (workoutDate == yesterday) return 'Yesterday';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final workoutsAsync = ref.watch(userWorkoutsProvider(userId));
    // ✅ ПРЕФЕТЧИНГ: загружаем упражнения для последних 10 тренировок
    workoutsAsync.whenData((workouts) {
      if (workouts.isEmpty) return;

      final recent = workouts.take(10).toList();
      debugPrint(
        '📦 [Pre-fetch] Caching exercises for ${recent.length} workouts',
      );

      for (final workout in recent) {
        // Загружаем и кэшируем
        ref
            .read(workoutExercisesProvider('$userId|${workout.id}').future)
            .then((exercises) {
              debugPrint(
                '  ✅ Cached ${exercises.length} exercises for ${workout.id}',
              );
            })
            .catchError((e) {
              debugPrint('  ❌ Failed to cache ${workout.id}: $e');
            });
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('My Workouts')),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(child: Text('No workouts yet. Create one!'));
          }
          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.fitness_center, color: Colors.blue),
                  ),
                  title: Text('Workout #${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDate(workout.date)),
                      if (workout.notes?.isNotEmpty ?? false)
                        Text(
                          '📝 ${workout.notes}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // ✅ Открываем тот же экран для просмотра/редактирования
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkoutDetailScreen(workoutId: workout.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        // ✅ Открываем тот же экран для создания новой тренировки
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const WorkoutDetailScreen(workoutId: null), // null = создание
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
