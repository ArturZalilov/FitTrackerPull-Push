import 'package:flutter/material.dart';

class ExerciseSetsScreen extends StatelessWidget {
  const ExerciseSetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Sets')),
      body: const Center(child: Text('Record Sets (Weight/Reps)')),
    );
  }
}
