import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercises_model.dart';

class ExercisesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Создать глобальное упражнение
  Future<String> createExercise(String userId, Exercise exercise) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .add(exercise.toMap());
    return doc.id;
  }

  // 🔹 Получить все глобальные упражнения пользователя
  Stream<List<Exercise>> getUserExercises(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Exercise.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // 🔹 Обновить глобальное упражнение (например, рекорд)
  Future<void> updateExercise(
    String userId,
    String exerciseId,
    Exercise exercise,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .update(exercise.toMap());
  }

  // 🔹 Удалить глобальное упражнение
  Future<void> deleteExercise(String userId, String exerciseId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .delete();
  }

  // 🔹 Получить одно упражнение по коду
  Future<Exercise?> getExerciseByCode(String userId, String code) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return Exercise.fromMap(doc.data(), doc.id);
    }
    return null;
  }
}
