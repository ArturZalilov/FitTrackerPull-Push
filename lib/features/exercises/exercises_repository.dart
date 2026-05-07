import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> deleteExercise(String userId, String exerciseId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .delete();
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
}
