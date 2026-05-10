import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'exercises_model.dart';

class ExercisesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createExercise(String userId, ExerciseModel exercise) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .add(exercise.toMap());
    return doc.id;
  }

  Stream<List<ExerciseModel>> getUserExercises(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExerciseModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateExercise(
    String userId,
    String exerciseId,
    ExerciseModel exercise,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .update(exercise.toMap());
  }

  Future<ExerciseModel?> getExerciseByCode(String userId, String code) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return ExerciseModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Future<void> deleteExercise(String userId, String exerciseId) async {
    debugPrint(
      '🗑️ [ExercisesRepository] Удаление: users/$userId/exercises/$exerciseId',
    );

    try {
      // 1. Удаляем упражнение из глобальной коллекции пользователя
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .delete();

      debugPrint('✅ [ExercisesRepository] Упражнение удалено');

      // 2. (Опционально) Удаляем упражнение из всех тренировок пользователя
      // Это предотвратит "битые" ссылки в тренировках
      await _removeExerciseFromAllWorkouts(userId, exerciseId);
    } catch (e, stack) {
      debugPrint('❌ [ExercisesRepository] Ошибка удаления: $e');
      debugPrint('📋 Stack: $stack');
      rethrow;
    }
  }

  // 🔹 Вспомогательный метод: удаляем упражнение из всех тренировок
  Future<void> _removeExerciseFromAllWorkouts(
    String userId,
    String exerciseCode,
  ) async {
    debugPrint('🔍 [ExercisesRepository] Поиск упражнения в тренировках...');

    final workoutsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .get();

    int removedCount = 0;

    for (final workoutDoc in workoutsSnapshot.docs) {
      final exercisesSnapshot = await workoutDoc.reference
          .collection('exercises')
          .where('exerciseCode', isEqualTo: exerciseCode)
          .get();

      for (final exerciseDoc in exercisesSnapshot.docs) {
        await exerciseDoc.reference.delete();
        removedCount++;
        debugPrint(
          '🗑️ Удалено из тренировки ${workoutDoc.id}: ${exerciseDoc.id}',
        );
      }
    }

    if (removedCount > 0) {
      debugPrint(
        '✅ [ExercisesRepository] Упражнение удалено из $removedCount тренировок',
      );
    }
  }
}
