import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import 'exercises_repository.dart';
import 'exercises_model.dart';

final exercisesRepositoryProvider = Provider((ref) => ExercisesRepository());

final userExercisesProvider =
    StreamProvider.family<List<ExerciseModel>, String>((ref, userId) {
      return ref.read(exercisesRepositoryProvider).getUserExercises(userId);
    });

class ExercisesNotifier extends Notifier<void> {
  @override
  void build() {}

  ExercisesRepository get _repo => ref.read(exercisesRepositoryProvider);
  String? get _userId => ref.read(authRepositoryProvider).currentUserId;

  Future<void> createExercise(
    String code,
    String name,
    String description,
    num record,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final exercise = ExerciseModel(
      id: '',
      code: code,
      name: name,
      description: description,
      record: record,
      createdAt: DateTime.now(),
    );

    await _repo.createExercise(userId, exercise);
  }

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

  Future<void> deleteExercise(String exerciseId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repo.deleteExercise(userId, exerciseId);
  }
}

final exercisesNotifierProvider = NotifierProvider<ExercisesNotifier, void>(
  ExercisesNotifier.new,
);
