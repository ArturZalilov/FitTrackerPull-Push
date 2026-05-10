import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth/auth_notifier.dart';
import 'user_model.dart';

final userNotifierProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.read(authRepositoryProvider).currentUserId;

  debugPrint('🔍 [UserNotifier] userId: $userId');

  if (userId == null) {
    debugPrint(
      '⚠️ [UserNotifier] userId is null — пользователь не авторизован',
    );
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
        debugPrint('📡 [UserNotifier] snapshot.exists: ${snapshot.exists}');
        if (snapshot.exists) {
          debugPrint('📡 [UserNotifier] snapshot. ${snapshot.data()}');
        }

        if (!snapshot.exists) {
          debugPrint('⚠️ [UserNotifier] Документ не найден');
          return null;
        }

        try {
          final profile = UserProfile.fromMap(snapshot.data()!, snapshot.id);
          debugPrint('✅ [UserNotifier] Профиль загружен: ${profile.name}');
          return profile;
        } catch (e, stack) {
          debugPrint('❌ [UserNotifier] Ошибка парсинга: $e');
          debugPrint('📋 Stack: $stack');
          rethrow;
        }
      })
      .handleError((error, stack) {
        // 🔥 ЛОВИМ ОШИБКУ СТРИМА И ЛОГИРУЕМ
        debugPrint('❌ [UserNotifier] Stream error: $error');
        debugPrint('📋 Stack: $stack');
        // Пробрасываем ошибку дальше, чтобы экран её увидел
        throw error;
      });
});
