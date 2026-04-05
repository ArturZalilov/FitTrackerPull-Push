import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String lastName;
  final String weight;
  final String height;
  final DateTime? dateTime;

  //конструктор
  UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    required this.weight,
    required this.height,
    required this.dateTime,
  });

  //конструктор для преобразование при получении из Firebase
  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      id: documentId,
      name: map['name'] ?? '',
      lastName: map['lastName'] ?? '',
      weight: map['weight'] ?? '',
      height: map['height'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
    );
  }

  //преобразование для добавления данных в Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'weight': weight,
      'height': height,
      'dateTime': dateTime,
    };
  }
}
