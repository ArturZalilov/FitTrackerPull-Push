// 📁 lib/features/workouts/workouts_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth/auth_notifier.dart';
import 'workouts_repository.dart';
import 'workouts_model.dart';

final workoutsRepositoryProvider = Provider((ref) => WorkoutsRepository());

// ✅ Список тренировок
final userWorkoutsProvider = StreamProvider.family<List<WorkoutModel>, String>((
  ref,
  userId,
) {
  return ref.read(workoutsRepositoryProvider).getUserWorkouts(userId);
});

// ✅ ОДНА тренировка — параметр: "userId|workoutId"
final workoutProvider = StreamProvider.family<WorkoutModel?, String>((
  ref,
  params,
) {
  final parts = params.split('|');
  if (parts.length != 2) return Stream.value(null);

  final userId = parts[0];
  final workoutId = parts[1];

  debugPrint(
    '🔍 [workoutProvider] Запрос: userId=$userId, workoutId=$workoutId',
  );

  if (userId.isEmpty || workoutId.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('workouts')
      .doc(workoutId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        final data = snapshot.data();
        if (data == null) return null;
        return WorkoutModel.fromMap(data, snapshot.id);
      })
      .handleError((error, stack) {
        debugPrint('❌ [workoutProvider] Error: $error');
        throw error;
      });
});

// ✅ Упражнения тренировки — параметр: "userId|workoutId"
final workoutExercisesProvider = StreamProvider.family<List<WorkoutExercise>, String>((
  ref,
  params,
) {
  final parts = params.split('|');
  if (parts.length != 2) return Stream.value([]);

  final userId = parts[0];
  final workoutId = parts[1];

  debugPrint(
    '🔍 [workoutExercisesProvider] Запрос: userId=$userId, workoutId=$workoutId',
  );

  if (userId.isEmpty || workoutId.isEmpty) return Stream.value([]);

  return ref
      .read(workoutsRepositoryProvider)
      .getWorkoutExercises(userId, workoutId)
      .map((exercises) {
        debugPrint(
          '✅ [workoutExercisesProvider] Получено: ${exercises.length} упражнений',
        );
        return exercises;
      })
      .handleError((error, stack) {
        debugPrint('❌ [workoutExercisesProvider] Error: $error');
        throw error;
      });
});

// ... остальной код (WorkoutsNotifier class) без изменений ...

class WorkoutsNotifier extends Notifier<void> {
  @override
  void build() {}

  WorkoutsRepository get _repo => ref.read(workoutsRepositoryProvider);
  String? get _userId => ref.read(authRepositoryProvider).currentUserId;

  Future<void> createWorkout(DateTime date, String? notes) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final workout = WorkoutModel(id: '', date: date, notes: notes);
    await _repo.createWorkout(userId, workout);
  }

  Future<void> addExerciseToWorkout(
    String workoutId,
    String exerciseCode,
    String exerciseName,
  ) async {
    final userId = _userId;
    if (userId == null) return;

    final workoutExercise = WorkoutExercise(
      id: '',
      exerciseCode: exerciseCode,
      exerciseName: exerciseName,
      sets: [],
    );
    await _repo.addExerciseToWorkout(userId, workoutId, workoutExercise);
  }

  Future<void> updateExerciseSets(
    String workoutId,
    String exerciseId,
    List<WorkoutSet> sets,
  ) async {
    final userId = _userId;
    if (userId == null) return;
    await _repo.updateWorkoutExerciseSets(userId, workoutId, exerciseId, sets);
  }

  Future<void> deleteWorkout(String workoutId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repo.deleteWorkout(userId, workoutId);
  }
}

final workoutsNotifierProvider = NotifierProvider<WorkoutsNotifier, void>(
  WorkoutsNotifier.new,
);
