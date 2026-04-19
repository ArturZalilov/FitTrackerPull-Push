import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exercises_notifier.dart';
import '../../auth/auth_notifier.dart';

class ExercisesScreen extends ConsumerWidget {
  final String? workoutId; // Optional (nullable)

  const ExercisesScreen({
    super.key,
    this.workoutId, // Не required
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return const Scaffold();

    final exercisesAsync = ref.watch(
      workoutExercisesProvider({'userId': userId, 'workoutId': workoutId}),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(
              context,
              '/create-exercise',
              arguments: workoutId,
            ),
          ),
        ],
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          if (exercises.isEmpty) {
            return const Center(child: Text('No exercises. Tap + to add.'));
          }
          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                title: Text(exercise.title),
                subtitle: Text(exercise.discription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/exercise-progress',
                    arguments: exercise.id,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
