import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutsModel {
  final String id;
  final int sets;
  final List<double> weight;
  final int reps;
  final DateTime date; // ✅ Новое поле

  WorkoutsModel({
    required this.id,
    required this.sets,
    required this.weight,
    required this.reps,
    required this.date,
  });

  // Из Firestore → Модель
  factory WorkoutsModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutsModel(
      id: id,
      sets: map['sets'] ?? 0,
      weight: List<double>.from(map['weight'] ?? []),
      reps: map['reps'] ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Модель → Firestore
  Map<String, dynamic> toMap() {
    return {
      'sets': sets,
      'weight': weight,
      'reps': reps,
      'date': Timestamp.fromDate(date), // ✅ Сохраняем как Timestamp
    };
  }

  // Копирование с обновлением полей
  WorkoutsModel copyWith({
    String? id,
    int? sets,
    List<double>? weight,
    int? reps,
    DateTime? date,
  }) {
    return WorkoutsModel(
      id: id ?? this.id,
      sets: sets ?? this.sets,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      date: date ?? this.date,
    );
  }
}
