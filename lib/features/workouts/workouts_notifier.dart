import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

final workoutProvider = StreamProvider.family<WorkoutModel?, String>((
  ref,
  params,
) {
  final parts = params.split('|');
  if (parts.length != 2) return Stream.value(null);
  final userId = parts[0];
  final workoutId = parts[1];
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

final workoutExercisesProvider =
    StreamProvider.family<List<WorkoutExercise>, String>((ref, params) {
      final parts = params.split('|');
      if (parts.length != 2) return Stream.value([]);
      final userId = parts[0];
      final workoutId = parts[1];
      if (userId.isEmpty || workoutId.isEmpty) return Stream.value([]);

      return ref
          .read(workoutsRepositoryProvider)
          .getWorkoutExercises(userId, workoutId)
          .map((exercises) {
            debugPrint(
              '✅ [workoutExercisesProvider] Loaded ${exercises.length} exercises',
            );
            return exercises;
          })
          .handleError((error, stack) {
            debugPrint('❌ [workoutExercisesProvider] Error: $error');
            throw error;
          });
    });

// ✅ ПОЛНОСТЬЮ ЗАМЕНИ ЭТОТ ПРОВАЙДЕР В workouts_notifier.dart
// ✅ УБРАЛИ ручной кэш - доверяем Riverpod
final exerciseProgressProvider = FutureProvider.autoDispose
    .family<List<ChartDataPoint>, String>((ref, exerciseCode) async {
      debugPrint('🚀 [ProgressProvider] START: exerciseCode=$exerciseCode');

      final userId = ref.read(authRepositoryProvider).currentUserId;
      if (userId == null) {
        debugPrint('❌ [ProgressProvider] No userId');
        return [];
      }

      try {
        // 1️⃣ Загружаем тренировки
        debugPrint('⏳ Loading workouts...');
        final workouts = await ref
            .read(userWorkoutsProvider(userId).future)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('⏰ Workouts timeout');
                return <WorkoutModel>[];
              },
            );

        debugPrint('📊 Found ${workouts.length} workouts');
        if (workouts.isEmpty) return [];

        // 2️⃣ Сортируем и ограничиваем
        final sorted = List.of(workouts)
          ..sort((a, b) => a.date.compareTo(b.date));
        final limited = sorted.length > 20 ? sorted.sublist(0, 20) : sorted;

        // 3️⃣ ✅ ПАРАЛЛЕЛЬНАЯ загрузка всех упражнений
        debugPrint('⏳ Loading exercises in parallel...');
        final exercisesList = await Future.wait(
          limited.map((workout) async {
            try {
              debugPrint('  🔍 Loading exercises for workout: ${workout.id}');

              final exercises = await ref
                  .read(
                    workoutExercisesProvider('$userId|${workout.id}').future,
                  )
                  .timeout(
                    const Duration(seconds: 3),
                    onTimeout: () {
                      debugPrint('  ⏰ Timeout for ${workout.id}');
                      return <WorkoutExercise>[];
                    },
                  );

              debugPrint(
                '  ✅ Loaded ${exercises.length} exercises for ${workout.id}',
              );
              return exercises;
            } catch (e) {
              debugPrint('  ❌ Error for ${workout.id}: $e');
              return <WorkoutExercise>[];
            }
          }).toList(),
        );

        // 4️⃣ Обрабатываем результаты
        final points = <ChartDataPoint>[];
        for (int i = 0; i < limited.length; i++) {
          final workout = limited[i];
          final exercises = exercisesList[i];

          // 🔍 Ищем упражнение (сравнение без учёта регистра)
          final matches = exercises.where((ex) {
            final codeMatch =
                ex.exerciseCode.toLowerCase() == exerciseCode.toLowerCase();
            if (codeMatch) {
              debugPrint('  ✅ MATCH: ${ex.exerciseCode} == $exerciseCode');
            }
            return codeMatch;
          }).toList();

          if (matches.isNotEmpty) {
            final weights = matches
                .expand((ex) => ex.sets)
                .map((s) => s.weight)
                .toList();
            debugPrint('  📊 Weights: $weights');

            if (weights.isNotEmpty) {
              final maxWeight = weights.reduce((a, b) => a > b ? a : b);
              points.add(
                ChartDataPoint(
                  x: i.toDouble(),
                  value: maxWeight.toDouble(),
                  date: workout.date,
                ),
              );
              debugPrint('  📈 Added point: ${maxWeight}kg on ${workout.date}');
            }
          } else {
            debugPrint('  ⚠️ No match in workout ${workout.id}');
          }
        }

        debugPrint(
          '✅ [ProgressProvider] DONE: ${points.length} points collected',
        );
        return points;
      } catch (e, stack) {
        debugPrint('💥 [ProgressProvider] CRITICAL ERROR: $e');
        debugPrint('📋 Stack: $stack');
        return [];
      }
    });

// 🔹 Модель данных для графика
class ChartDataPoint {
  final double x;
  final double value;
  final DateTime date;
  ChartDataPoint({required this.x, required this.value, required this.date});
}

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
