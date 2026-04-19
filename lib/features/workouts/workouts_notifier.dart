import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import 'workouts_repository.dart';
import 'workouts_model.dart';

final workoutsRepositoryProvider = Provider((ref) => WorkoutsRepository());

final userWorkoutsProvider = StreamProvider.family<List<WorkoutsModel>, String>(
  (ref, userId) {
    return ref.read(workoutsRepositoryProvider).getUserWorkouts(userId);
  },
);

final workoutProvider =
    FutureProvider.family<WorkoutsModel?, Map<String, String>>((ref, params) {
      final userId = params['userId']!;
      final workoutId = params['workoutId']!;
      return ref.read(workoutsRepositoryProvider).getWorkout(userId, workoutId);
    });

class WorkoutsNotifier extends Notifier<void> {
  @override
  void build() {}

  WorkoutsRepository get _repo => ref.read(workoutsRepositoryProvider);
  String? get _userId => ref.read(authRepositoryProvider).currentUserId;

  // Создать тренировку с датой
  Future<void> createWorkout(
    int sets,
    List<double> weight,
    int reps,
    DateTime date,
  ) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');

    final workout = WorkoutsModel(
      id: '',
      sets: sets,
      weight: weight,
      reps: reps,
      date: date,
    );

    await _repo.createWorkout(userId, workout);
  }

  // Обновить тренировку
  Future<void> updateWorkout(
    String workoutId,
    int sets,
    List<double> weight,
    int reps,
    DateTime date,
  ) async {
    final userId = _userId;
    if (userId == null) return;

    final workout = WorkoutsModel(
      id: workoutId,
      sets: sets,
      weight: weight,
      reps: reps,
      date: date,
    );

    await _repo.updateWorkout(userId, workoutId, workout);
  }

  // Удалить тренировку
  Future<void> deleteWorkout(String workoutId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repo.deleteWorkout(userId, workoutId);
  }
}

final workoutsNotifierProvider = NotifierProvider<WorkoutsNotifier, void>(
  WorkoutsNotifier.new,
);
