import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id; // ID документа в Firestore
  final String code; // Уникальный код: "bench_press", "squat", etc.
  final String name; // Название для отображения
  final String description; // Описание техники
  final num record; // Личный рекорд (для графика)
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.record,
    required this.createdAt,
  });

  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    return Exercise(
      id: id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      record: map['record'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'record': record,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Exercise copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    num? record,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      record: record ?? this.record,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
