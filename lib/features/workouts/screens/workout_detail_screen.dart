// 📁 lib/features/workouts/screens/workout_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../workouts_notifier.dart';
import '../workouts_model.dart';
import '../../auth/auth_notifier.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String? workoutId;

  const WorkoutDetailScreen({super.key, this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  late bool _isCreating;
  late DateTime _selectedDate;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isCreating = widget.workoutId == null;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _handleCreate() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authRepositoryProvider).currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final workout = WorkoutModel(
        id: '',
        date: _selectedDate,
        notes: _notesController.text.trim(),
      );
      final newWorkoutId = await ref
          .read(workoutsRepositoryProvider)
          .createWorkout(userId, workout);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workoutId: newWorkoutId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete(String workoutId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить тренировку?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref
          .read(workoutsNotifierProvider.notifier)
          .deleteWorkout(workoutId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null)
      return const Scaffold(
        body: Center(child: Text('Пожалуйста, войдите в систему')),
      );

    // ✅ РЕЖИМ СОЗДАНИЯ
    if (_isCreating) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Новая тренировка'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.calendar_today, color: Colors.blue),
                  ),
                  title: const Text('Дата тренировки'),
                  subtitle: Text(_formatDate(_selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Заметки (необязательно)',
                      hintText: 'Что планируем делать сегодня?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    maxLines: 3,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Создать тренировку',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    // ✅ РЕЖИМ ПРОСМОТРА / РЕДАКТИРОВАНИЯ
    final params = '$userId|${widget.workoutId!}';
    final workoutAsync = ref.watch(workoutProvider(params));
    final exercisesAsync = ref.watch(workoutExercisesProvider(params));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Детали тренировки'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _handleDelete(widget.workoutId!),
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null)
            return const Center(child: Text('Тренировка не найдена'));

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(workout.date),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (workout.notes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📝 ${workout.notes}',
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Упражнения',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: exercisesAsync.when(
                  data: (exercises) {
                    if (exercises.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.blueGrey.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Пока нет упражнений',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Нажмите + чтобы добавить',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        return _buildExerciseCard(
                          widget.workoutId!,
                          exercises[index],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Ошибка: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка загрузки: $err')),
      ),
      floatingActionButton: workoutAsync.when(
        data: (workout) => FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/select-exercise',
              arguments: {'workoutId': widget.workoutId!, 'existingCodes': []},
            );
          },
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        loading: () => null,
        error: (err, _) => null,
      ),
    );
  }

  Widget _buildExerciseCard(String workoutId, WorkoutExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          exercise.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'ID: ${exercise.exerciseCode}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.fitness_center, color: Colors.blue),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Вес (кг)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Повторы',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...exercise.sets.asMap().entries.map((entry) {
            return _SetRowWidget(
              workoutId: workoutId,
              exerciseId: exercise.id,
              setIndex: entry.key,
              set: entry.value,
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () async {
                final updatedSets = List<WorkoutSet>.from(exercise.sets)
                  ..add(WorkoutSet(weight: 0, reps: 0, completed: false));
                await ref
                    .read(workoutsNotifierProvider.notifier)
                    .updateExerciseSets(workoutId, exercise.id, updatedSets);
              },
              icon: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Colors.blue,
              ),
              label: const Text(
                'Добавить подход',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ ОТДЕЛЬНЫЙ ВИДЖЕТ ДЛЯ СТРОКИ ПОДХОДА (ConsumerStatefulWidget)
class _SetRowWidget extends ConsumerStatefulWidget {
  final String workoutId;
  final String exerciseId;
  final int setIndex;
  final WorkoutSet set;

  const _SetRowWidget({
    required this.workoutId,
    required this.exerciseId,
    required this.setIndex,
    required this.set,
  });

  @override
  ConsumerState<_SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends ConsumerState<_SetRowWidget> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.set.weight.toString());
    _repsCtrl = TextEditingController(text: widget.set.reps.toString());
  }

  @override
  void didUpdateWidget(covariant _SetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.set.weight != oldWidget.set.weight) {
      _weightCtrl.text = widget.set.weight.toString();
    }
    if (widget.set.reps != oldWidget.set.reps) {
      _repsCtrl.text = widget.set.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final newWeight = num.tryParse(_weightCtrl.text) ?? widget.set.weight;
    final newReps = int.tryParse(_repsCtrl.text) ?? widget.set.reps;
    final completed = widget.set.completed;

    final userId = ref.read(authRepositoryProvider).currentUserId;

    if (userId != null) {
      final currentExercisesAsync = ref.read(
        workoutExercisesProvider('${userId}|${widget.workoutId}'),
      );

      if (currentExercisesAsync is AsyncData<List<WorkoutExercise>>) {
        final exercises = currentExercisesAsync.value;
        final exIndex = exercises.indexWhere((e) => e.id == widget.exerciseId);

        if (exIndex != -1) {
          final exercise = exercises[exIndex];
          final updatedSets = List<WorkoutSet>.from(exercise.sets);

          if (widget.setIndex < updatedSets.length) {
            updatedSets[widget.setIndex] = WorkoutSet(
              weight: newWeight,
              reps: newReps,
              completed: completed,
            );

            ref
                .read(workoutsNotifierProvider.notifier)
                .updateExerciseSets(
                  widget.workoutId,
                  widget.exerciseId,
                  updatedSets,
                );
          }
        }
      }
    }
  }

  void _saveChangesWithOverride({
    required bool completed,
    required num weight,
    required int reps,
  }) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;

    if (userId != null) {
      final currentExercisesAsync = ref.read(
        workoutExercisesProvider('${userId}|${widget.workoutId}'),
      );

      if (currentExercisesAsync is AsyncData<List<WorkoutExercise>>) {
        final exercises = currentExercisesAsync.value;
        final exIndex = exercises.indexWhere((e) => e.id == widget.exerciseId);

        if (exIndex != -1) {
          final exercise = exercises[exIndex];
          final updatedSets = List<WorkoutSet>.from(exercise.sets);

          if (widget.setIndex < updatedSets.length) {
            updatedSets[widget.setIndex] = WorkoutSet(
              weight: weight,
              reps: reps,
              completed: completed,
            );

            ref
                .read(workoutsNotifierProvider.notifier)
                .updateExerciseSets(
                  widget.workoutId,
                  widget.exerciseId,
                  updatedSets,
                );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                '#${widget.setIndex + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onSubmitted: (_) => _saveChanges(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onSubmitted: (_) => _saveChanges(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Checkbox(
              value: widget.set.completed,
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) {
                if (value != null) {
                  final currentWeight =
                      num.tryParse(_weightCtrl.text) ?? widget.set.weight;
                  final currentReps =
                      int.tryParse(_repsCtrl.text) ?? widget.set.reps;
                  _saveChangesWithOverride(
                    completed: value,
                    weight: currentWeight,
                    reps: currentReps,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
