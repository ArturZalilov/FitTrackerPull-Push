import 'package:cloud_firestore/cloud_firestore.dart';

// 🔹 Подход в конкретной тренировке
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

// 🔹 Упражнение ВНУТРИ тренировки (ссылка на глобальное + подходы)
class WorkoutExercise {
  final String id; // ID документа в подколлекции
  final String exerciseCode; // 🔗 Ссылка на глобальное упражнение
  final String exerciseName; // 📋 Копия названия для быстрого отображения
  final List<WorkoutSet> sets; // 📊 Подходы этой тренировки

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

// 🔹 Сама тренировка
class WorkoutModel {
  final String id;
  final DateTime date;
  final String? notes;
  final List<WorkoutExercise> exercises; // Список упражнений этой тренировки

  WorkoutModel({
    required this.id,
    required this.date,
    this.notes,
    required this.exercises,
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutModel(
      id: id,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
      exercises:
          (map['exercises'] as List?)
              ?.map(
                (e) => WorkoutExercise.fromMap(
                  e as Map<String, dynamic>,
                  e['id'] ?? '',
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
}
