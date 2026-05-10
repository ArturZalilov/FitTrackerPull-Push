// 📁 lib/features/users/user_model.dart

class UserProfile {
  final String id;
  final String name;
  final String lastName;
  final String email;
  final String weight;
  final String height;

  UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.weight,
    required this.height,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '', // 🔥 Проверь: в Firebase поле называется 'name'?
      lastName:
          map['lastName'] ?? '', // 🔥 Проверь: 'lastName' или 'last_name'?
      email: map['email'] ?? '', // 🔥 Проверь: есть ли поле 'email'?
      weight: map['weight'] ?? '', // 🔥 Проверь: 'weight' или 'Weight'?
      height: map['height'] ?? '', // 🔥 Проверь: 'height' или 'Height'?
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'email': email,
      'weight': weight,
      'height': height,
    };
  }
}
