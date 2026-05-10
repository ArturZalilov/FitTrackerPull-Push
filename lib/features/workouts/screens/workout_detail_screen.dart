// 📁 lib/features/workouts/screens/workout_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../workouts_notifier.dart';
import '../workouts_model.dart';
import '../../exercises/exercises_notifier.dart';
import '../../auth/auth_notifier.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String?
  workoutId; // null = создание новой, не null = просмотр существующей

  const WorkoutDetailScreen({super.key, this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  late bool _isCreating;
  late DateTime _selectedDate;
  final _notesController = TextEditingController();
  final _selectedExerciseCodes =
      <String, String>{}; // code → name (только для создания)
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

  // 🔹 Загрузка данных существующей тренировки
  void _loadExistingWorkout(WorkoutModel workout) {
    _selectedDate = workout.date;
    _notesController.text = workout.notes ?? '';
    // Упражнения загружаются через workoutExercisesProvider
  }

  // 🔹 Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // 🔹 Выбор даты
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // 🔹 Диалог выбора упражнений (для создания и добавления)
  void _showExerciseSelectionDialog({bool multiSelect = false}) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final exercisesAsync = ref.watch(userExercisesProvider(userId));
        return AlertDialog(
          title: Text(multiSelect ? 'Select Exercises' : 'Add Exercise'),
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
                      Text('Create exercises first in Exercises tab'),
                    ],
                  );
                }
                if (multiSelect) {
                  // ✅ Множественный выбор (для создания)
                  return ListView(
                    shrinkWrap: true,
                    children: exercises.map((ex) {
                      final isSelected = _selectedExerciseCodes.containsKey(
                        ex.code,
                      );
                      return CheckboxListTile(
                        title: Text(ex.name),
                        subtitle: Text(ex.description),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedExerciseCodes[ex.code] = ex.name;
                            } else {
                              _selectedExerciseCodes.remove(ex.code);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                } else {
                  // ✅ Одиночный выбор (для добавления в существующую)
                  return ListView(
                    shrinkWrap: true,
                    children: exercises.map((ex) {
                      return ListTile(
                        title: Text(ex.name),
                        subtitle: Text(ex.description),
                        trailing: const Icon(Icons.add),
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (!_isCreating && widget.workoutId != null) {
                            try {
                              await ref
                                  .read(workoutsNotifierProvider.notifier)
                                  .addExerciseToWorkout(
                                    widget.workoutId!,
                                    ex.code,
                                    ex.name,
                                  );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${ex.name} added'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      );
                    }).toList(),
                  );
                }
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
            if (multiSelect)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Упражнения добавятся при создании тренировки
                },
                child: Text('Add (${_selectedExerciseCodes.length})'),
              ),
          ],
        );
      },
    );
  }

  // 🔹 Создание новой тренировки
  Future<void> _handleCreate() async {
    if (_selectedExerciseCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one exercise'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authRepositoryProvider).currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // 1. Создаём тренировку
      final workout = WorkoutModel(
        id: '',
        date: _selectedDate,
        notes: _notesController.text.trim(),
      );
      final workoutId = await ref
          .read(workoutsRepositoryProvider)
          .createWorkout(userId, workout);

      debugPrint('✅ [WorkoutDetail] Тренировка создана: $workoutId');

      // 2. Добавляем упражнения
      for (final entry in _selectedExerciseCodes.entries) {
        await ref
            .read(workoutsNotifierProvider.notifier)
            .addExerciseToWorkout(workoutId, entry.key, entry.value);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Возврат на список тренировок
      }
    } catch (e) {
      debugPrint('❌ [WorkoutDetail] Ошибка создания: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 Удаление тренировки
  Future<void> _handleDelete(String workoutId) async {
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
    if (confirm == true && mounted) {
      await ref
          .read(workoutsNotifierProvider.notifier)
          .deleteWorkout(workoutId);
      if (mounted) Navigator.pop(context);
    }
  }

  // 🔹 Обновление подхода
  Future<void> _updateSet(
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

  // 🔹 Добавление нового подхода
  Future<void> _addNewSet(
    String workoutId,
    WorkoutExercise workoutExercise,
  ) async {
    final updatedSets = List<WorkoutSet>.from(workoutExercise.sets)
      ..add(WorkoutSet(weight: 0, reps: 0, completed: false));
    await ref
        .read(workoutsNotifierProvider.notifier)
        .updateExerciseSets(workoutId, workoutExercise.id, updatedSets);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    // ✅ Режим создания
    if (_isCreating) {
      return _buildCreateMode();
    }

    // ✅ Режим просмотра/редактирования
    if (widget.workoutId == null) {
      return const Scaffold(body: Center(child: Text('Invalid workout ID')));
    }

    final params = '$userId|${widget.workoutId!}';
    final workoutAsync = ref.watch(workoutProvider(params));
    final exercisesAsync = ref.watch(workoutExercisesProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _handleDelete(widget.workoutId!),
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) return _buildNotFound();
          _loadExistingWorkout(workout); // Загружаем данные в контроллеры
          return _buildViewMode(
            workout,
            exercisesAsync,
            userId,
            widget.workoutId!,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError('Failed to load workout', err),
      ),
    );
  }

  // 🔹 Режим создания новой тренировки
  Widget _buildCreateMode() {
    return Scaffold(
      appBar: AppBar(title: const Text('New Workout')),
      body: Stack(
        children: [
          Form(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Дата
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Заметки
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional notes...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  // Выбор упражнений
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Exercises:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _showExerciseSelectionDialog(
                                multiSelect: true,
                              ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_selectedExerciseCodes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No exercises selected',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      children: _selectedExerciseCodes.entries.map((entry) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(entry.value),
                            subtitle: Text('Code: ${entry.key}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(
                                      () => _selectedExerciseCodes.remove(
                                        entry.key,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Кнопка создания
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Workout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // 🔹 Режим просмотра/редактирования
  Widget _buildViewMode(
    WorkoutModel workout,
    AsyncValue<List<WorkoutExercise>> exercisesAsync,
    String userId,
    String workoutId,
  ) {
    return Column(
      children: [
        // Карточка тренировки
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  Text(
                    '📝 ${workout.notes}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Заголовок упражнений + кнопка добавления
        Padding(
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
                onPressed: () =>
                    _showExerciseSelectionDialog(multiSelect: false),
                tooltip: 'Add Exercise',
              ),
            ],
          ),
        ),
        // Список упражнений
        Expanded(
          child: exercisesAsync.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return const Center(
                  child: Text('No exercises yet. Tap + to add.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: exercises.length,
                itemBuilder: (context, index) =>
                    _buildExerciseTile(workoutId, exercises[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildError('Failed to load exercises', err),
          ),
        ),
      ],
    );
  }

  // 🔹 Карточка упражнения с подходами
  Widget _buildExerciseTile(String workoutId, WorkoutExercise workoutExercise) {
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
          _buildSetsHeader(),
          const Divider(height: 1),
          ..._buildSetRows(workoutId, workoutExercise),
          _buildAddSetButton(workoutId, workoutExercise),
        ],
      ),
    );
  }

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

  List<Widget> _buildSetRows(
    String workoutId,
    WorkoutExercise workoutExercise,
  ) {
    return workoutExercise.sets.asMap().entries.map((entry) {
      final index = entry.key;
      final set = entry.value;
      return _buildSetRow(workoutId, workoutExercise, index + 1, set, index);
    }).toList();
  }

  Widget _buildSetRow(
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
          Expanded(
            flex: 1,
            child: Text(
              '#$setNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildEditableField(
              initialValue: set.weight.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onSave: (value) async {
                final newWeight = num.tryParse(value) ?? set.weight;
                await _updateSet(
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
          Expanded(
            flex: 2,
            child: _buildEditableField(
              initialValue: set.reps.toString(),
              keyboardType: TextInputType.number,
              onSave: (value) async {
                final newReps = int.tryParse(value) ?? set.reps;
                await _updateSet(
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

  Widget _buildAddSetButton(String workoutId, WorkoutExercise workoutExercise) {
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
      onTap: () => _addNewSet(workoutId, workoutExercise),
    );
  }

  Widget _buildNotFound() {
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

  Widget _buildError(String title, Object error) {
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
}
