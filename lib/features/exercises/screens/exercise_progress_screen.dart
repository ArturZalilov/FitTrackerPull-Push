import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  final String? exerciseId; // ✅ Добавь ? (сделай nullable)

  const ExerciseProgressScreen({
    super.key,
    this.exerciseId, // ✅ Убери 'required' если есть
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Для демо: показываем заглушку прогресса
    // В реальном проекте: добавить историю подходов в модель

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Progress tracking will appear here'),
                    const SizedBox(height: 8),
                    Text(
                      'Exercise ID: $exerciseId',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
