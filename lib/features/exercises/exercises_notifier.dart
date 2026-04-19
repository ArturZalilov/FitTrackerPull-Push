import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import 'exercises_repository.dart';
import 'exercises_model.dart';

// Провайдер репозитория
final exercisesRepositoryProvider = Provider((ref) => ExercisesRepository());

// Провайдер списка упражнений тренировки
final workoutExercisesProvider =
    StreamProvider.family<List<Exercise>, Map<String, String>>((ref, params) {
      final userId = params['userId']!;
      final workoutId = params['workoutId']!;
      return ref
          .read(exercisesRepositoryProvider)
          .getWorkoutExercises(userId, workoutId);
    });

// Notifier для операций с упражнениями
class ExercisesNotifier extends Notifier<void> {
  @override
  void build() {}

  ExercisesRepository get _repo => ref.read(exercisesRepositoryProvider);
  String? get _userId => ref.read(authRepositoryProvider).currentUserId;

  // Создать упражнение
  Future<void> createExercise(
    String workoutId,
    String title,
    String discription,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final exercise = Exercise(
      id: '', // Firestore сгенерирует
      title: title,
      discription: discription,
    );

    await _repo.createExercise(userId, workoutId, exercise);
  }

  // Обновить упражнение
  Future<void> updateExercise(
    String workoutId,
    String exerciseId,
    String title,
    String discription,
  ) async {
    final userId = _userId;
    if (userId == null) return;

    final exercise = Exercise(
      id: exerciseId,
      title: title,
      discription: discription,
    );

    await _repo.updateExercise(userId, workoutId, exerciseId, exercise);
  }

  // Удалить упражнение
  Future<void> deleteExercise(String workoutId, String exerciseId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repo.deleteExercise(userId, workoutId, exerciseId);
  }
}

final exercisesNotifierProvider = NotifierProvider<ExercisesNotifier, void>(
  ExercisesNotifier.new,
);
