import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import 'workouts_repository.dart';
import 'workouts_model.dart';

final workoutsRepositoryProvider = Provider((ref) => WorkoutsRepository());

final userWorkoutsProvider = StreamProvider.family<List<WorkoutModel>, String>((
  ref,
  userId,
) {
  return ref.read(workoutsRepositoryProvider).getUserWorkouts(userId);
});

final workoutProvider =
    FutureProvider.family<WorkoutModel?, Map<String, String>>((
      ref,
      params,
    ) async {
      final userId = params['userId'];
      final workoutId = params['workoutId'];
      if (userId == null || workoutId == null) return null;
      return await ref
          .read(workoutsRepositoryProvider)
          .getWorkout(userId, workoutId);
    });

final workoutExercisesProvider =
    StreamProvider.family<List<WorkoutExercise>, Map<String, String>>((
      ref,
      params,
    ) {
      final userId = params['userId']!;
      final workoutId = params['workoutId']!;
      return ref
          .read(workoutsRepositoryProvider)
          .getWorkoutExercises(userId, workoutId);
    });

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
