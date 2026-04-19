import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../workouts_notifier.dart';
import '../../auth/auth_notifier.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  // Форматирование даты
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
                      Text('${workout.sets} sets × ${workout.reps} reps'),
                      const SizedBox(height: 4),
                      // 📅 Дата тренировки
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(workout.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/workout-detail',
                      arguments: workout.id,
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
        onPressed: () => Navigator.pushNamed(context, '/create-workout'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
