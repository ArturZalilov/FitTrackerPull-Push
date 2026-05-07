import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import 'exercises_repository.dart';
import 'exercises_model.dart';

final exercisesRepositoryProvider = Provider((ref) => ExercisesRepository());

// 🔹 Список глобальных упражнений пользователя
final userExercisesProvider = StreamProvider.family<List<Exercise>, String>((
  ref,
  userId,
) {
  return ref.read(exercisesRepositoryProvider).getUserExercises(userId);
});

class ExercisesNotifier extends Notifier<void> {
  @override
  void build() {}

  ExercisesRepository get _repo => ref.read(exercisesRepositoryProvider);
  String? get _userId => ref.read(authRepositoryProvider).currentUserId;

  // 🔹 Создать новое глобальное упражнение
  Future<void> createExercise(
    String code,
    String name,
    String description,
    num record,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final exercise = Exercise(
      id: '',
      code: code,
      name: name,
      description: description,
      record: record,
      createdAt: DateTime.now(),
    );

    await _repo.createExercise(userId, exercise);
  }

  // 🔹 Обновить рекорд упражнения
  Future<void> updateRecord(String exerciseId, num newRecord) async {
    final userId = _userId;
    if (userId == null) return;

    final exercise = await _repo.getExerciseByCode(userId, exerciseId);
    if (exercise == null) return;

    await _repo.updateExercise(
      userId,
      exerciseId,
      exercise.copyWith(record: newRecord),
    );
  }

  // 🔹 Удалить глобальное упражнение
  Future<void> deleteExercise(String exerciseId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repo.deleteExercise(userId, exerciseId);
  }
}

final exercisesNotifierProvider = NotifierProvider<ExercisesNotifier, void>(
  ExercisesNotifier.new,
);
