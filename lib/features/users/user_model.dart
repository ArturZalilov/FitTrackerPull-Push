class UserProfile {
  final String id;
  final String name;
  final String lastName;
  final String weight;
  final String height;

  //конструктор
  UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    required this.weight,
    required this.height,
  });

  //конструктор для преобразование при получении из Firebase
  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      id: documentId,
      name: map['name'] ?? '',
      lastName: map['lastName'] ?? '',
      weight: map['weight'] ?? '',
      height: map['height'] ?? '',
    );
  }

  //преобразование для добавления данных в Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'weight': weight,
      'height': height,
    };
  }
}
