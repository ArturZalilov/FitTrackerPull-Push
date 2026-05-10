// 📁 lib/features/exercises/screens/select_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exercises/exercises_notifier.dart';
import '../../workouts/workouts_notifier.dart';
import '../../auth/auth_notifier.dart';

class SelectExerciseScreen extends ConsumerStatefulWidget {
  final String workoutId;
  final List<String> existingExerciseCodes; // Чтобы не добавлять дубликаты

  const SelectExerciseScreen({
    super.key,
    required this.workoutId,
    this.existingExerciseCodes = const [],
  });

  @override
  ConsumerState<SelectExerciseScreen> createState() =>
      _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends ConsumerState<SelectExerciseScreen> {
  final _selectedCodes = <String>{};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String code, String name) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
      } else {
        _selectedCodes.add(code);
      }
    });
  }

  Future<void> _addSelectedExercises() async {
    if (_selectedCodes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Показываем загрузку (можно улучшить через SnackBar или Overlay)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final notifier = ref.read(workoutsNotifierProvider.notifier);
      // Получаем список всех упражнений, чтобы найти названия
      final userId = ref.read(authRepositoryProvider).currentUserId!;
      final allExercises = await ref.read(userExercisesProvider(userId).future);

      int addedCount = 0;
      for (final code in _selectedCodes) {
        final exercise = allExercises.firstWhere((e) => e.code == code);
        try {
          await notifier.addExerciseToWorkout(
            widget.workoutId,
            code,
            exercise.name,
          );
          addedCount++;
        } catch (e) {
          debugPrint('Error adding $code: $e');
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Закрываем лоадер
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добавлено упражнений: $addedCount'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context); // Возвращаемся к тренировке
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authRepositoryProvider).currentUserId!;
    final exercisesAsync = ref.watch(userExercisesProvider(userId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Добавить упражнения'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (_selectedCodes.isNotEmpty)
            TextButton(
              onPressed: _addSelectedExercises,
              child: Text(
                'Добавить (${_selectedCodes.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск упражнения...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // 📋 Список
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                // Фильтрация
                final filtered = exercises.where((e) {
                  final matchesSearch = e.name.toLowerCase().contains(
                    _searchQuery,
                  );
                  final notAlreadyAdded = !widget.existingExerciseCodes
                      .contains(e.code);
                  return matchesSearch && notAlreadyAdded;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.existingExerciseCodes.isNotEmpty &&
                                  _searchQuery.isEmpty
                              ? 'Все упражнения уже добавлены'
                              : 'Ничего не найдено',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ex = filtered[index];
                    final isSelected = _selectedCodes.contains(ex.code);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade700,
                          // TODO: Сюда можно потом поставить картинку
                          child: const Icon(Icons.fitness_center),
                          radius: 24,
                        ),
                        title: Text(
                          ex.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(ex.description),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(
                                Icons.add_circle_outline,
                                color: Colors.grey,
                              ),
                        onTap: () => _toggleSelection(ex.code, ex.name),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Ошибка: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
