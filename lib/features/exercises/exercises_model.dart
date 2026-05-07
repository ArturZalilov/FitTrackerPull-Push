import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseModel {
  final String id;
  final String code;
  final String name;
  final String description;
  final num record;
  final DateTime createdAt;

  ExerciseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.record,
    required this.createdAt,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExerciseModel(
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

  ExerciseModel copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    num? record,
    DateTime? createdAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      record: record ?? this.record,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
