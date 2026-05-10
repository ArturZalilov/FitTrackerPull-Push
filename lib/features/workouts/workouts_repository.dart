// 📁 lib/features/workouts/workouts_repository.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'workouts_model.dart';

class WorkoutsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createWorkout(String userId, WorkoutModel workout) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .add(workout.toMap());
    return doc.id;
  }

  // ✅ ИСПРАВЛЕНО: добавлен таймаут и правильный возврат ошибки
  Future<WorkoutModel?> getWorkout(String userId, String workoutId) async {
    debugPrint(
      '🔌 [WorkoutsRepository] Запрос: users/$userId/workouts/$workoutId',
    );

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId)
          .get()
          .timeout(
            const Duration(seconds: 10), // ⏱️ Если дольше 10 сек — таймаут
            onTimeout: () {
              debugPrint(
                '❌ [WorkoutsRepository] ТАЙМАУТ: Firestore не ответил',
              );
              throw Exception('Firestore timeout: no response in 10 seconds');
            },
          );

      debugPrint('📡 [WorkoutsRepository] exists: ${doc.exists}');

      if (!doc.exists) {
        debugPrint('⚠️ [WorkoutsRepository] Документ не найден');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('⚠️ [WorkoutsRepository] data is null');
        return null;
      }

      final workout = WorkoutModel.fromMap(data, doc.id);
      debugPrint('✅ [WorkoutsRepository] Возвращаю: ${workout.date}');
      return workout;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ [WorkoutsRepository] FirebaseAuthException: ${e.code} - ${e.message}',
      );
      rethrow; // ← Пробрасываем, чтобы экран увидел ошибку
    } on TimeoutException catch (e) {
      debugPrint('❌ [WorkoutsRepository] Timeout: $e');
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ [WorkoutsRepository] Unknown error: $e');
      debugPrint('📋 Stack: $stack');
      rethrow; // ← Обязательно!
    }
  }

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

  Future<void> deleteWorkout(String userId, String workoutId) async {
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

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .delete();
  }
}
