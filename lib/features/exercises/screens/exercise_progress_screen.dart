import 'package:flutter/material.dart';

class ExerciseProgressScreen extends StatelessWidget {
  const ExerciseProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Progress')),
      body: const Center(child: Text('Progress Charts & Statistics')),
    );
  }
}
