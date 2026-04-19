class Exercise {
  final String id;
  final String title;
  final String discription;

  Exercise({required this.id, required this.title, required this.discription});

  factory Exercise.fromMap(Map<String, dynamic> map, String documentId) {
    return Exercise(
      id: documentId,
      title: map['title'] ?? '',
      discription: map['discription'] ?? '',
    );
  }

  //преобразование для добавления данных в Firebase
  Map<String, dynamic> toMap() {
    return {'title': title, 'discription': discription};
  }
}
