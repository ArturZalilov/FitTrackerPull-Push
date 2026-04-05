class WorkoutsModel {
  final String id;
  final int sets;
  final List<double> weight;
  final int reps;

  WorkoutsModel({
    required this.id,
    required this.sets,
    required this.weight,
    required this.reps,
  });

  factory WorkoutsModel.fromMap(Map<String, dynamic> map, String documentId) {
    return WorkoutsModel(
      id: documentId,
      sets: map['sets'] ?? 0,
      weight: List<double>.from(map['weight'] ?? []),
      reps: map['reps'] ?? 0,
    );
  }

  //преобразование для добавления данных в Firebase
  Map<String, dynamic> toMap() {
    return {'sets': sets, 'weight': weight, 'reps': reps};
  }
}
