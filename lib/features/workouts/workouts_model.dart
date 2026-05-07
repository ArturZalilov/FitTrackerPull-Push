import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSet {
  final num weight;
  final int reps;
  final bool completed;

  WorkoutSet({
    required this.weight,
    required this.reps,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
    'weight': weight,
    'reps': reps,
    'completed': completed,
  };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: map['weight'] ?? 0,
      reps: map['reps'] ?? 0,
      completed: map['completed'] ?? false,
    );
  }
}

class WorkoutExercise {
  final String id;
  final String exerciseCode;
  final String exerciseName;
  final List<WorkoutSet> sets;

  WorkoutExercise({
    required this.id,
    required this.exerciseCode,
    required this.exerciseName,
    required this.sets,
  });

  Map<String, dynamic> toMap() => {
    'exerciseCode': exerciseCode,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toMap()).toList(),
  };

  factory WorkoutExercise.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutExercise(
      id: id,
      exerciseCode: map['exerciseCode'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets:
          (map['sets'] as List?)
              ?.map((s) => WorkoutSet.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkoutModel {
  final String id;
  final DateTime date;
  final String? notes;

  WorkoutModel({required this.id, required this.date, this.notes});

  factory WorkoutModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutModel(
      id: id,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': Timestamp.fromDate(date), 'notes': notes};
  }
}
