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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
      final newId = await ref
          .read(workoutsRepositoryProvider)
          .createWorkout(userId, workout);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workoutId: newId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
        title: const Text(
          'Удалить тренировку?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
      return _buildCreateMode();
    }

    // ✅ РЕЖИМ ПРОСМОТРА / РЕДАКТИРОВАНИЯ
    final params = '$userId|${widget.workoutId!}';
    final workoutAsync = ref.watch(workoutProvider(params));
    final exercisesAsync = ref.watch(workoutExercisesProvider(params));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Тренировка'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _handleDelete(widget.workoutId!),
            tooltip: 'Удалить тренировку',
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) return _buildNotFound();

          return Column(
            children: [
              // 📅 Карточка информации
              _buildInfoCard(workout),

              // 🏋️ Заголовок упражнений
              _buildExercisesHeader(),

              // 📋 Список упражнений
              Expanded(
                child: exercisesAsync.when(
                  data: (exercises) =>
                      _buildExercisesList(widget.workoutId!, exercises),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      _buildError('Ошибка загрузки упражнений', err.toString()),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            _buildError('Ошибка загрузки тренировки', err.toString()),
      ),
      floatingActionButton: workoutAsync.when(
        data: (workout) => _buildFloatingActionButton(),
        loading: () => null,
        error: (err, _) => null,
      ),
    );
  }

  // 🔹 Режим создания тренировки
  Widget _buildCreateMode() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Новая тренировка'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🎯 Иконка-заголовок
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 45,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 📅 Карточка даты
            _buildInfoTile(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: 'Дата тренировки',
              subtitle: _formatDate(_selectedDate),
              onTap: () => _selectDate(context),
              isInteractive: true,
            ),
            const SizedBox(height: 16),

            // 📝 Карточка заметок
            Card(
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notes,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Заметки',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Что планируем сделать сегодня?',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 4,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ✅ Кнопка создания
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Создать тренировку',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 🔹 Карточка информации о тренировке
  Widget _buildInfoCard(WorkoutModel workout) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дата проведения',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(workout.date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (workout.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Заметки',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      workout.notes!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🔹 Заголовок раздела упражнений
  Widget _buildExercisesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Упражнения',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fitness_center, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Добавить',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Список упражнений
  Widget _buildExercisesList(
    String workoutId,
    List<WorkoutExercise> exercises,
  ) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Пока нет упражнений',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить первое',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        return _buildExerciseCard(workoutId, exercises[index]);
      },
    );
  }

  // 🔹 Карточка упражнения
  Widget _buildExerciseCard(String workoutId, WorkoutExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          exercise.exerciseName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center,
            color: Colors.white,
            size: 24,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          // Заголовки колонок
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Center(child: Text('#', style: _headerStyle())),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Вес', style: _headerStyle())),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Повт.', style: _headerStyle())),
                ),
                SizedBox(
                  width: 44,
                  child: Center(child: Text('✓', style: _headerStyle())),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Подходы
          ...exercise.sets.asMap().entries.map((entry) {
            return _SetRowWidget(
              workoutId: workoutId,
              exerciseId: exercise.id,
              setIndex: entry.key,
              set: entry.value,
            );
          }).toList(),

          // Кнопка добавления подхода
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Стиль заголовков колонок
  TextStyle _headerStyle() => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade600,
  );

  // 🔹 Карточка-кнопка для интерактивных элементов
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isInteractive,
  }) {
    return InkWell(
      onTap: isInteractive ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: isInteractive ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isInteractive ? Colors.white : Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isInteractive)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Плавающая кнопка добавления упражнений
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/select-exercise',
          arguments: {'workoutId': widget.workoutId!, 'existingCodes': []},
        );
      },
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Упражнение'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      hoverElevation: 6,
      tooltip: 'Добавить упражнение',
    );
  }

  // 🔹 Состояние "не найдено"
  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
          ),
          const SizedBox(height: 20),
          const Text(
            'Тренировка не найдена',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Назад'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Состояние ошибки
  Widget _buildError(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ ОТДЕЛЬНЫЙ ВИДЖЕТ ДЛЯ СТРОКИ ПОДХОДА (без изменений логики)
// Только визуальные улучшения
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Номер подхода
          SizedBox(
            width: 32,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${widget.setIndex + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Поле Веса
          Expanded(
            flex: 2,
            child: _buildInputField(
              controller: _weightCtrl,
              hint: '0',
              suffix: 'кг',
              onSave: (_) => _saveChanges(),
            ),
          ),
          const SizedBox(width: 8),

          // Поле Повторов
          Expanded(
            flex: 2,
            child: _buildInputField(
              controller: _repsCtrl,
              hint: '0',
              suffix: 'раз',
              onSave: (_) => _saveChanges(),
            ),
          ),
          const SizedBox(width: 8),

          // Галочка (Чекбокс)
          SizedBox(
            width: 44,
            child: Container(
              decoration: BoxDecoration(
                color: widget.set.completed
                    ? Colors.green.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Checkbox(
                value: widget.set.completed,
                activeColor: Colors.green,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
          ),
        ],
      ),
    );
  }

  // 🔹 Вспомогательный виджет для полей ввода
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required Function(String) onSave,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: suffix == 'кг'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 8,
          ),
        ),
        onSubmitted: onSave,
      ),
    );
  }
}
