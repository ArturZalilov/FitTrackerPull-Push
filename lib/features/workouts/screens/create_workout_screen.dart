// 📁 lib/features/workouts/screens/create_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../workouts_model.dart';
import '../workouts_notifier.dart';
import '../../exercises/exercises_notifier.dart';
import '../../auth/auth_notifier.dart';

class CreateWorkoutScreen extends ConsumerStatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  ConsumerState<CreateWorkoutScreen> createState() =>
      _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends ConsumerState<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();
  final _selectedExerciseCodes = <String, String>{}; // code → name
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // 🔹 Диалог выбора упражнений из глобальной библиотеки
  void _showExerciseSelectionDialog() {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final exercisesAsync = ref.watch(userExercisesProvider(userId));
        return AlertDialog(
          title: const Text('Select Exercises'),
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
                      Text('Create exercises first in Exercises tab'),
                    ],
                  );
                }
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text('Add (${_selectedExerciseCodes.length})'),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Создание тренировки с упражнениями
  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authRepositoryProvider).currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // 1. Создаём тренировку
      final workoutId = await ref
          .read(workoutsRepositoryProvider)
          .createWorkout(
            userId,
            WorkoutModel(
              id: '',
              date: _selectedDate,
              notes: _notesController.text.trim(),
            ),
          );

      debugPrint('✅ [CreateWorkout] Тренировка создана: $workoutId');

      // 2. Добавляем ВСЕ выбранные упражнения (по одному)
      if (_selectedExerciseCodes.isNotEmpty) {
        int addedCount = 0;
        for (final entry in _selectedExerciseCodes.entries) {
          try {
            await ref
                .read(workoutsNotifierProvider.notifier)
                .addExerciseToWorkout(
                  workoutId,
                  entry.key, // exerciseCode
                  entry.value, // exerciseName
                );
            addedCount++;
            debugPrint(
              '✅ [CreateWorkout] Добавлено упражнение: ${entry.value} ($addedCount/${_selectedExerciseCodes.length})',
            );
          } catch (e) {
            debugPrint(
              '❌ [CreateWorkout] Ошибка добавления ${entry.value}: $e',
            );
            // Продолжаем добавлять остальные, даже если одно не получилось
          }
        }
        debugPrint('✅ [CreateWorkout] Всего добавлено упражнений: $addedCount');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout created with ${_selectedExerciseCodes.length} exercises',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ [CreateWorkout] Ошибка: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Workout')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
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
                  // Выбранные упражнения
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
                            : _showExerciseSelectionDialog,
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
          // Индикатор загрузки поверх всего
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
