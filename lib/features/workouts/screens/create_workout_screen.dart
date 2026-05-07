import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../workouts_notifier.dart';
import '../workouts_model.dart'; // ✅ ДОБАВЬ ЭТУ СТРОКУ!
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

  // 🔹 Диалог выбора упражнения из глобальной библиотеки
  void _addExerciseDialog() {
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
                  return const Text(
                    'No exercises yet. Create one in Exercises tab first!',
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
                        if (checked == true) {
                          setState(
                            () => _selectedExerciseCodes[ex.code] = ex.name,
                          );
                        } else {
                          setState(
                            () => _selectedExerciseCodes.remove(ex.code),
                          );
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
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
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = ref.read(authRepositoryProvider).currentUserId;
      if (userId == null) return;

      // 1. Создаём тренировку (без упражнений — они добавятся отдельно)
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

      // 2. Добавляем выбранные упражнения как отдельные записи
      for (final entry in _selectedExerciseCodes.entries) {
        await ref
            .read(workoutsNotifierProvider.notifier)
            .addExerciseToWorkout(
              workoutId,
              entry.key, // exerciseCode
              entry.value, // exerciseName
            );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Workout')),
      body: Form(
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addExerciseDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_selectedExerciseCodes.isEmpty)
                const Text(
                  'No exercises selected',
                  style: TextStyle(color: Colors.grey),
                ),
              ..._selectedExerciseCodes.entries.map(
                (e) => ListTile(
                  title: Text(e.value),
                  subtitle: Text('Code: ${e.key}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () =>
                        setState(() => _selectedExerciseCodes.remove(e.key)),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _handleCreate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Workout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
