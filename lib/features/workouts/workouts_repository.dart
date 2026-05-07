import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<WorkoutModel?> getWorkout(String userId, String workoutId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId)
          .get();

      if (doc.exists) {
        return WorkoutModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching workout: $e');
      return null;
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
