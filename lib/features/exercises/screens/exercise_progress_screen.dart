// 📁 lib/features/exercises/screens/exercise_progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../auth/auth_notifier.dart';
import '../../workouts/workouts_notifier.dart';
import '../../workouts/workouts_model.dart';

class ExerciseProgressScreen extends ConsumerStatefulWidget {
  const ExerciseProgressScreen({super.key});

  @override
  ConsumerState<ExerciseProgressScreen> createState() =>
      _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState
    extends ConsumerState<ExerciseProgressScreen> {
  String? _exerciseCode;
  String? _exerciseName;
  bool _showMaxWeight = true; // Переключатель: макс. вес / средний вес

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Безопасное извлечение аргументов
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _exerciseCode = args?['exerciseCode'] as String?;
    _exerciseName = args?['exerciseName'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    if (_exerciseCode == null) {
      return _buildEmptyState(
        'Exercise not selected',
        'Go back and tap on an exercise',
      );
    }

    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null)
      return const Scaffold(body: Center(child: Text('Please login')));

    final workoutsAsync = ref.watch(userWorkoutsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_exerciseName ?? 'Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: workoutsAsync.when(
          data: (workouts) => _buildContent(workouts),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              _buildEmptyState('Error loading data', err.toString()),
        ),
      ),
    );
  }

  // 🔹 Пустое состояние / ошибка
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 72,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Основной контент с графиком
  Widget _buildContent(List<WorkoutModel> workouts) {
    if (workouts.isEmpty) {
      return _buildEmptyState(
        'No workouts yet',
        'Create a workout to start tracking your progress',
      );
    }

    return FutureBuilder<List<_ChartData>>(
      future: _collectChartData(workouts),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildEmptyState('Error', 'Could not load chart data');
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return _buildEmptyState(
            'No data for this exercise',
            'Add this exercise to your workouts to see progress',
          );
        }

        return Column(
          children: [
            // 📊 Статистика
            _buildStatsCard(data),
            // 🔄 Переключатель типа данных
            _buildToggleSwitch(),
            // 📈 График
            Expanded(child: _buildChart(data)),
            // 📋 Легенда
            _buildLegend(),
          ],
        );
      },
    );
  }

  // 🔹 Карточка со статистикой
  Widget _buildStatsCard(List<_ChartData> data) {
    final maxWeight = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minWeight = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final improvement = maxWeight - minWeight;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Max',
              '${maxWeight.toStringAsFixed(1)} kg',
              Colors.green,
            ),
            _buildStatItem(
              'Min',
              '${minWeight.toStringAsFixed(1)} kg',
              Colors.orange,
            ),
            _buildStatItem(
              'Improvement',
              '+${improvement.toStringAsFixed(1)} kg',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 🔹 Переключатель: макс. вес / средний
  Widget _buildToggleSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption('Max Weight', true),
            _buildToggleOption('Avg Weight', false),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isMax) {
    final isSelected = _showMaxWeight == isMax;
    return GestureDetector(
      onTap: () => setState(() => _showMaxWeight = isMax),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // 🔹 Сам график
  Widget _buildChart(List<_ChartData> data) {
    final spots = data.map((d) => FlSpot(d.x, d.value)).toList();
    final minY = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.5,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${value.toInt()}kg',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final date = data.firstWhereOrNull((d) => d.x == value)?.date;
                  if (date == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd.MM').format(date),
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: data.length - 1,
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.blue,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.blue.withOpacity(0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blue.shade800,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final dataPoint = data[spot.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('dd.MM.yyyy').format(dataPoint.date)}\n${dataPoint.value.toStringAsFixed(1)} kg',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Легенда под графиком
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 24, height: 3, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Weight progression',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // 🔹 Сбор данных для графика
  Future<List<_ChartData>> _collectChartData(
    List<WorkoutModel> workouts,
  ) async {
    final result = <_ChartData>[];
    final userId = ref.read(authRepositoryProvider).currentUserId!;
    int index = 0;

    // Сортируем от старых к новым
    final sortedWorkouts = List.of(workouts)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final workout in sortedWorkouts) {
      try {
        // ✅ Стало (правильно):
        final exercises = await ref.read(
          workoutExercisesProvider('$userId|${workout.id}').future,
        );

        final matching = exercises
            .where((ex) => ex.exerciseCode == _exerciseCode)
            .toList();
        if (matching.isEmpty) {
          index++;
          continue;
        }

        double value = 0;
        if (_showMaxWeight) {
          // Максимальный вес среди всех подходов
          value = matching
              .expand((ex) => ex.sets)
              .map((s) => s.weight)
              .reduce((a, b) => a > b ? a : b)
              .toDouble();
        } else {
          // Средний вес среди завершённых подходов
          final completed = matching.expand(
            (ex) => ex.sets.where((s) => s.completed),
          );
          if (completed.isNotEmpty) {
            value =
                completed.map((s) => s.weight).reduce((a, b) => a + b) /
                completed.length;
          }
        }

        result.add(
          _ChartData(x: index.toDouble(), value: value, date: workout.date),
        );
        index++;
      } catch (e) {
        debugPrint('⚠️ Error loading exercises for workout ${workout.id}: $e');
      }
    }

    return result;
  }
}

// 🔹 Модель данных для графика
class _ChartData {
  final double x;
  final double value;
  final DateTime date;

  _ChartData({required this.x, required this.value, required this.date});
}

// 🔹 Extension для firstWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
