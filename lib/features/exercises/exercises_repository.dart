import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercises_model.dart';

class ExercisesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Создать упражнение в тренировке
  Future<String> createExercise(
    String userId,
    String workoutId,
    Exercise exercise,
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

  // Получить все упражнения тренировки
  Stream<List<Exercise>> getWorkoutExercises(String userId, String workoutId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Exercise.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Обновить упражнение
  Future<void> updateExercise(
    String userId,
    String workoutId,
    String exerciseId,
    Exercise exercise,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .update(exercise.toMap());
  }

  // Удалить упражнение
  Future<void> deleteExercise(
    String userId,
    String workoutId,
    String exerciseId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .delete();
  }

  // Получить одно упражнение
  Future<Exercise?> getExercise(
    String userId,
    String workoutId,
    String exerciseId,
  ) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .get();
    if (doc.exists) {
      return Exercise.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
