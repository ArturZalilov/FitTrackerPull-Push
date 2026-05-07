import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../workouts_notifier.dart';
import '../workouts_model.dart'; // ✅ ДОБАВЬ ЭТУ СТРОКУ!
import '../../auth/auth_notifier.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return const Scaffold();

    final workoutAsync = ref.watch(
      workoutProvider({'userId': userId, 'workoutId': workoutId}),
    );
    final exercisesAsync = ref.watch(
      workoutExercisesProvider({'userId': userId, 'workoutId': workoutId}),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Workout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref
                    .read(workoutsNotifierProvider.notifier)
                    .deleteWorkout(workoutId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('Workout not found'));
          }

          return Column(
            children: [
              // 📅 Карточка с информацией о тренировке
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Дата
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(workout.date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (workout.notes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text('Notes: ${workout.notes}'),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      // ✅ Статистику считаем из упражнений (ниже)
                    ],
                  ),
                ),
              ),
              const Divider(),
              // Заголовок упражнений
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/add-exercise',
                          arguments: workoutId,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // ✅ Список упражнений с подходами
              Expanded(
                child: exercisesAsync.when(
                  data: (exercises) {
                    if (exercises.isEmpty) {
                      return const Center(
                        child: Text('No exercises yet. Tap + to add.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final workoutExercise = exercises[index];
                        return ExpansionTile(
                          title: Text(workoutExercise.exerciseName),
                          subtitle: Text(
                            'Code: ${workoutExercise.exerciseCode}',
                          ),
                          children: [
                            // Заголовки таблицы
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Set',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Weight',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Reps',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Done?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Подходы
                            ...workoutExercise.sets.asMap().entries.map((
                              entry,
                            ) {
                              final setIndex = entry.key + 1;
                              final set = entry.value;
                              return ListTile(
                                dense: true,
                                title: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text('#$setIndex'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('${set.weight} kg'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('${set.reps}'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Checkbox(
                                        value: set.completed,
                                        onChanged: (value) async {
                                          if (value == null) return;
                                          final updatedSets =
                                              List<WorkoutSet>.from(
                                                workoutExercise.sets,
                                              );
                                          updatedSets[entry.key] = WorkoutSet(
                                            weight: set.weight,
                                            reps: set.reps,
                                            completed: value,
                                          );
                                          await ref
                                              .read(
                                                workoutsNotifierProvider
                                                    .notifier,
                                              )
                                              .updateExerciseSets(
                                                workoutId,
                                                workoutExercise.id,
                                                updatedSets,
                                              );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            // Кнопка добавить подход
                            ListTile(
                              title: const Text(
                                'Add Set',
                                style: TextStyle(color: Colors.blue),
                              ),
                              leading: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.blue,
                              ),
                              onTap: () async {
                                final updatedSets =
                                    List<WorkoutSet>.from(workoutExercise.sets)
                                      ..add(
                                        WorkoutSet(
                                          weight: 0,
                                          reps: 0,
                                          completed: false,
                                        ),
                                      );
                                await ref
                                    .read(workoutsNotifierProvider.notifier)
                                    .updateExerciseSets(
                                      workoutId,
                                      workoutExercise.id,
                                      updatedSets,
                                    );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
