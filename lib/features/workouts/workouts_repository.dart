import 'package:cloud_firestore/cloud_firestore.dart';
import 'workouts_model.dart';

class WorkoutsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Создать тренировку
  Future<String> createWorkout(String userId, WorkoutsModel workout) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .add(workout.toMap());
    return doc.id;
  }

  // Получить все тренировки пользователя (сортировка по дате)
  Stream<List<WorkoutsModel>> getUserWorkouts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('date', descending: true) // ✅ Сортируем по дате
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutsModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Обновить тренировку
  Future<void> updateWorkout(
    String userId,
    String workoutId,
    WorkoutsModel workout,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .update(workout.toMap());
  }

  // Удалить тренировку
  Future<void> deleteWorkout(String userId, String workoutId) async {
    // Сначала удаляем упражнения
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

  // Получить одну тренировку
  Future<WorkoutsModel?> getWorkout(String userId, String workoutId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .get();
    if (doc.exists) {
      return WorkoutsModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
