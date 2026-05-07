import 'package:cloud_firestore/cloud_firestore.dart';
import 'workouts_model.dart';

class WorkoutsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Создать тренировку
  Future<String> createWorkout(String userId, WorkoutModel workout) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .add(workout.toMap());
    return doc.id;
  }

  // 🔹 Получить все тренировки пользователя
  Stream<List<WorkoutModel>> getUserWorkouts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // 🔹 Добавить упражнение в тренировку
  Future<String> addExerciseToWorkout(
    String userId,
    String workoutId,
    WorkoutExercise exercise,
  ) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .add(exercise.toMap());
    return doc.id;
  }

  // 🔹 Получить упражнения конкретной тренировки
  Stream<List<WorkoutExercise>> getWorkoutExercises(
    String userId,
    String workoutId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutExercise.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // 🔹 Обновить подходы упражнения в тренировке
  Future<void> updateWorkoutExerciseSets(
    String userId,
    String workoutId,
    String exerciseId,
    List<WorkoutSet> sets,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .update({'sets': sets.map((s) => s.toMap()).toList()});
  }

  // 🔹 Удалить тренировку (и все её упражнения)
  Future<void> deleteWorkout(String userId, String workoutId) async {
    // Сначала удаляем все упражнения тренировки
    final exercisesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .get();

    final batch = _firestore.batch();
    for (var doc in exercisesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Затем саму тренировку
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .delete();
  }
}
