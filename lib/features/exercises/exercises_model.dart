class ExercisesModel {
  final String id;
  final String title;
  final String discription;

  ExercisesModel({
    required this.id,
    required this.title,
    required this.discription,
  });

  factory ExercisesModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExercisesModel(
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
