// 📁 lib/features/users/ui/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_notifier.dart';
import '../../workouts/workouts_notifier.dart';
import '../user_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    final userData = ref.watch(userNotifierProvider);
    final workoutsAsync = userId != null
        ? ref.watch(userWorkoutsProvider(userId))
        : const AsyncValue.data([]);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Настройки
            },
          ),
        ],
      ),
      body: userData.when(
        data: (userProfile) {
          if (userProfile == null) return _buildEmptyProfile();
          return _buildProfileContent(
            context,
            ref,
            userProfile,
            workoutsAsync,
            userId!,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(ref, err),
      ),
    );
  }

  Widget _buildEmptyProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text(
            'Профиль не найден',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    dynamic userProfile,
    AsyncValue<List<dynamic>> workoutsAsync,
    String userId,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 👤 Аватар + имя + почта
        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 55,
                      color: Colors.white,
                    ),
                  ),
                  // ✅ Бейдж "онлайн" (декоративный)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${userProfile.name} ${userProfile.lastName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                userProfile.email ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 📊 Быстрая статистика (горизонтальные карточки)
        _buildSectionTitle('Активность'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickStatCard(
                icon: Icons.fitness_center,
                label: 'Тренировок',
                value: workoutsAsync.when(
                  data: (w) => '${w.length}',
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildQuickStatCard(
                icon: Icons.local_fire_department,
                label: 'Серия',
                value: _calculateStreak(workoutsAsync),
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildQuickStatCard(
                icon: Icons.upgrade,
                label: 'Личный рекорд',
                value: _getPersonalBest(workoutsAsync),
                color: Colors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 📈 Детальная статистика
        _buildSectionTitle('Параметры'),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildStatItem(
                  icon: Icons.monitor_weight,
                  iconColor: Colors.green,
                  label: 'Вес',
                  value: userProfile.weight.isNotEmpty
                      ? '${userProfile.weight} кг'
                      : 'Не указан',
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildStatItem(
                  icon: Icons.height,
                  iconColor: Colors.purple,
                  label: 'Рост',
                  value: userProfile.height.isNotEmpty
                      ? '${userProfile.height} см'
                      : 'Не указан',
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildStatItem(
                  icon: Icons.bolt,
                  iconColor: Colors.blue,
                  label: 'Всего поднято',
                  value: _calculateTotalWeight(workoutsAsync),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 🔧 Меню
        _buildSectionTitle('Меню'),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline,
                iconColor: Colors.blue,
                label: 'Редактировать профиль',
                onTap: () => _showComingSoon(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                iconColor: Colors.orange,
                label: 'Уведомления',
                onTap: () => _showComingSoon(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.help_outline,
                iconColor: Colors.grey,
                label: 'Помощь и поддержка',
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 🚪 Выход
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 22),
            ),
            title: const Text(
              'Выйти из аккаунта',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showLogoutConfirmation(context, ref),
          ),
        ),
        const SizedBox(height: 40),

        // ℹ️ Версия
        Center(
          child: Text(
            'FitTracker v1.0.0',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  // 🔹 Заголовок раздела
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // 🔹 Быстрая статистика (горизонтальная карточка)
  Widget _buildQuickStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // 🔹 Строка статистики
  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Пункт меню
  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  // 🔹 Диалог выхода
  Future<void> _showLogoutConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Выйти?'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // 🔹 Заглушка "Скоро"
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция в разработке 🚧'),
        backgroundColor: Colors.grey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🔹 Состояние ошибки
  Widget _buildErrorState(WidgetRef ref, Object error) {
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
              'Не удалось загрузить профиль',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(userNotifierProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Повторить'),
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

  // 🔹 Расчёт серии (упрощённо)
  String _calculateStreak(AsyncValue<List<dynamic>> workoutsAsync) {
    // ✅ Проверяем на AsyncData
    if (workoutsAsync is! AsyncData) return '0';

    // ✅ Проверяем на null
    final workouts = workoutsAsync.value;
    if (workouts == null || workouts.isEmpty) return '0';

    // ✅ Простая логика: считаем тренировки за последние 7 дней
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = workouts.where((w) => w.date.isAfter(weekAgo)).length;

    return recent > 0 ? '$recent🔥' : '0';
  }

  // 🔹 Личный рекорд (упрощённо)
  String _getPersonalBest(AsyncValue<List<dynamic>> workoutsAsync) {
    if (workoutsAsync is! AsyncData) return '—';
    // Заглушка: в реальном приложении нужно агрегировать данные
    return '—';
  }

  // 🔹 Общий поднятый вес (упрощённо)
  String _calculateTotalWeight(AsyncValue<List<dynamic>> workoutsAsync) {
    if (workoutsAsync is! AsyncData) return '—';
    // Заглушка: нужен доступ к подходам
    return '—';
  }
}
