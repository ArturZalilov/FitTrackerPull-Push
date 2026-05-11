// 📁 lib/features/exercises/screens/exercise_progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../workouts/workouts_notifier.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  const ExerciseProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем аргументы маршрута
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final exerciseCode = args?['exerciseCode'] as String?;
    final exerciseName = args?['exerciseName'] as String?;

    if (exerciseCode == null) {
      return _buildEmptyState(
        context,
        'Exercise not selected',
        'Go back and tap on an exercise',
      );
    }

    // Следим за провайдером данных
    final progressAsync = ref.watch(exerciseProgressProvider(exerciseCode));

    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseName ?? 'Progress'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          // 🔄 Кнопка принудительного обновления
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('🔄 Manual refresh triggered');
              ref.invalidate(exerciseProgressProvider(exerciseCode));
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        // 🔄 Pull-to-refresh
        child: RefreshIndicator(
          onRefresh: () async {
            debugPrint('🔄 Pull-to-refresh triggered');
            ref.invalidate(exerciseProgressProvider(exerciseCode));
            await ref.read(exerciseProgressProvider(exerciseCode).future);
          },
          child: progressAsync.when(
            data: (data) => _buildContent(context, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildErrorWithRetry(
              context,
              ref,
              exerciseCode,
              err.toString(),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Основной скроллящийся контент
  Widget _buildContent(BuildContext context, List<ChartDataPoint> data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [_buildStatsCard(data), _buildChart(data), _buildLegend()],
      ),
    );
  }

  // 🔹 Карточка статистики
  Widget _buildStatsCard(List<ChartDataPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data.map((d) => d.value).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final improvement = max - min;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Max',
                '${max.toStringAsFixed(1)} kg',
                Colors.green,
              ),
              _buildStatItem(
                'Min',
                '${min.toStringAsFixed(1)} kg',
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

  // 🔹 График (фиксированная высота для корректной работы внутри ScrollView)
  Widget _buildChart(List<ChartDataPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = data.map((d) => FlSpot(d.x, d.value)).toList();
    final values = data.map((d) => d.value).toList();

    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      final padding = maxY * 0.2;
      minY -= padding;
      maxY += padding;
    } else {
      final padding = (maxY - minY) * 0.2;
      minY -= padding;
      maxY += padding;
    }

    final horizontalInterval = (maxY - minY) / 4;
    final safeInterval = horizontalInterval > 0 ? horizontalInterval : 1.0;

    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: safeInterval,
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
                  getTitlesWidget: (value, _) => Padding(
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
                  getTitlesWidget: (value, _) {
                    final point = data.firstWhereOrNull((d) => d.x == value);
                    if (point == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('dd.MM').format(point.date),
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
            maxX: data.length > 1 ? data.length.toDouble() - 1 : 1.0,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
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
                  final point = data[spot.x.toInt()];
                  return LineTooltipItem(
                    '${DateFormat('dd.MM.yyyy').format(point.date)}\n${point.value.toStringAsFixed(1)} kg',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Экран ошибки с кнопкой "Повторить"
  Widget _buildErrorWithRetry(
    BuildContext context,
    WidgetRef ref,
    String exerciseCode,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Не удалось загрузить данные',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 Retry button pressed');
                ref.invalidate(exerciseProgressProvider(exerciseCode));
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
