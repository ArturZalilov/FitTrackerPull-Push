// 📁 lib/features/workouts/screens/workout_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exercises/exercises_notifier.dart';
import '../workouts_notifier.dart';
import '../workouts_model.dart';
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
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    // ✅ Оба провайдера используют String-параметр "userId|workoutId"
    final params = '$userId|$workoutId';
    final workoutAsync = ref.watch(workoutProvider(params));
    final exercisesAsync = ref.watch(workoutExercisesProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref, workoutId),
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return _buildNotFound(context);
          }
          return _buildContent(
            context,
            ref,
            workout,
            exercisesAsync,
            userId,
            workoutId,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            _buildError(context, 'Failed to load workout', err),
      ),
    );
  }

  // 🔹 Подтверждение удаления
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String workoutId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
  }

  // 🔹 Экран "не найдено"
  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Workout not found', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // 🔹 Экран ошибки
  Widget _buildError(BuildContext context, String title, Object error) {
    debugPrint('❌ [WorkoutDetail] $title: $error');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // 🔹 Основной контент
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    WorkoutModel workout,
    AsyncValue<List<WorkoutExercise>> exercisesAsync,
    String userId,
    String workoutId,
  ) {
    return Column(
      children: [
        // 📅 Карточка тренировки
        _buildWorkoutCard(workout),
        const Divider(height: 1),
        // 🏋️ Заголовок упражнений
        _buildExercisesHeader(context, workoutId),
        // 📋 Список упражнений
        Expanded(
          child: exercisesAsync.when(
            data: (exercises) => _buildExercisesList(ref, workoutId, exercises),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                _buildError(context, 'Failed to load exercises', err),
          ),
        ),
      ],
    );
  }

  // 🔹 Карточка с датой и заметками
  Widget _buildWorkoutCard(WorkoutModel workout) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
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
              Text(
                '📝 ${workout.notes}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🔹 Заголовок + кнопка добавления
  Widget _buildExercisesHeader(BuildContext context, String workoutId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Exercises',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blue),
            onPressed: () => _showAddExerciseDialog(context, workoutId),
            tooltip: 'Add Exercise',
          ),
        ],
      ),
    );
  }

  // 🔹 Список упражнений
  Widget _buildExercisesList(
    WidgetRef ref,
    String workoutId,
    List<WorkoutExercise> exercises,
  ) {
    if (exercises.isEmpty) {
      return const Center(child: Text('No exercises yet. Tap + to add.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: exercises.length,
      itemBuilder: (context, index) =>
          _buildExerciseTile(ref, workoutId, exercises[index]),
    );
  }

  // 🔹 Карточка упражнения с подходами
  Widget _buildExerciseTile(
    WidgetRef ref,
    String workoutId,
    WorkoutExercise workoutExercise,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          workoutExercise.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Code: ${workoutExercise.exerciseCode}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        initiallyExpanded: true,
        children: [
          // Заголовки таблицы
          _buildSetsHeader(),
          const Divider(height: 1),
          // Подходы
          ..._buildSetRows(ref, workoutId, workoutExercise),
          // Кнопка "Добавить подход"
          _buildAddSetButton(ref, workoutId, workoutExercise),
        ],
      ),
    );
  }

  // 🔹 Заголовки столбцов
  Widget _buildSetsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(
            flex: 1,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'kg',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'reps',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '✓',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Диалог добавления существующего упражнения
  void _showAddExerciseDialog(
    BuildContext context,
    WidgetRef ref,
    String workoutId,
  ) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final exercisesAsync = ref.watch(userExercisesProvider(userId));
        return AlertDialog(
          title: const Text('Add Exercise'),
          content: SizedBox(
            width: double.maxFinite,
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No exercises yet'),
                      SizedBox(height: 8),
                      Text('Go to Exercises tab to create exercises first'),
                    ],
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: exercises.map((ex) {
                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text(ex.description),
                      trailing: const Icon(Icons.add),
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await ref
                              .read(workoutsNotifierProvider.notifier)
                              .addExerciseToWorkout(
                                workoutId,
                                ex.code,
                                ex.name,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${ex.name} added'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text('Error: $err'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Строки подходов
  List<Widget> _buildSetRows(
    WidgetRef ref,
    String workoutId,
    WorkoutExercise workoutExercise,
  ) {
    return workoutExercise.sets.asMap().entries.map((entry) {
      final index = entry.key;
      final set = entry.value;
      return _buildSetRow(
        ref,
        workoutId,
        workoutExercise,
        index + 1,
        set,
        index,
      );
    }).toList();
  }

  // 🔹 Одна строка подхода (с редактированием)
  Widget _buildSetRow(
    WidgetRef ref,
    String workoutId,
    WorkoutExercise workoutExercise,
    int setNumber,
    WorkoutSet set,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Номер
          Expanded(
            flex: 1,
            child: Text(
              '#$setNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Вес
          Expanded(
            flex: 2,
            child: _buildEditableField(
              initialValue: set.weight.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onSave: (value) async {
                final newWeight = num.tryParse(value) ?? set.weight;
                await _updateSet(
                  ref,
                  workoutId,
                  workoutExercise,
                  index,
                  newWeight,
                  set.reps,
                  set.completed,
                );
              },
            ),
          ),
          // Повторы
          Expanded(
            flex: 2,
            child: _buildEditableField(
              initialValue: set.reps.toString(),
              keyboardType: TextInputType.number,
              onSave: (value) async {
                final newReps = int.tryParse(value) ?? set.reps;
                await _updateSet(
                  ref,
                  workoutId,
                  workoutExercise,
                  index,
                  set.weight,
                  newReps,
                  set.completed,
                );
              },
            ),
          ),
          // Чекбокс
          Expanded(
            flex: 2,
            child: Checkbox(
              value: set.completed,
              activeColor: Colors.green,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (value) async {
                if (value == null) return;
                await _updateSet(
                  ref,
                  workoutId,
                  workoutExercise,
                  index,
                  set.weight,
                  set.reps,
                  value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Поле для редактирования (вес/повторы)
  Widget _buildEditableField({
    required String initialValue,
    required TextInputType keyboardType,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          isDense: true,
        ),
        onSubmitted: (value) {
          onSave(value);
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );
  }

  // 🔹 Кнопка "Добавить подход"
  Widget _buildAddSetButton(
    WidgetRef ref,
    String workoutId,
    WorkoutExercise workoutExercise,
  ) {
    return ListTile(
      dense: true,
      title: const Text(
        'Add Set',
        style: TextStyle(color: Colors.blue, fontSize: 14),
      ),
      leading: const Icon(
        Icons.add_circle_outline,
        color: Colors.blue,
        size: 20,
      ),
      onTap: () async {
        final updatedSets = List<WorkoutSet>.from(workoutExercise.sets)
          ..add(WorkoutSet(weight: 0, reps: 0, completed: false));
        await ref
            .read(workoutsNotifierProvider.notifier)
            .updateExerciseSets(workoutId, workoutExercise.id, updatedSets);
      },
    );
  }

  // 🔹 Обновление подхода в Firebase
  Future<void> _updateSet(
    WidgetRef ref,
    String workoutId,
    WorkoutExercise workoutExercise,
    int index,
    num newWeight,
    int newReps,
    bool completed,
  ) async {
    final updatedSets = List<WorkoutSet>.from(workoutExercise.sets);
    updatedSets[index] = WorkoutSet(
      weight: newWeight,
      reps: newReps,
      completed: completed,
    );
    await ref
        .read(workoutsNotifierProvider.notifier)
        .updateExerciseSets(workoutId, workoutExercise.id, updatedSets);
  }
}
