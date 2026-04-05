import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fit_tracker_pull_and_push/features/users/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, UserProfile>(
  () {
    return UserNotifier();
  },
);

class UserNotifier extends AsyncNotifier<UserProfile> {
  StreamSubscription? _subscription;
  @override
  Future<UserProfile> build() async {
    final uid = ref.read(authRepositoryProvider).currentUserId;
    if (uid == null) {
      return UserProfile(
        id: '',
        name: '',
        lastName: '',
        weight: '',
        height: '',
        dateTime: null,
      );
    }
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots() // 🔥 Стрим: Firebase сам пришлёт обновление
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              state = AsyncValue.data(UserProfile.fromMap(data, uid));
            }
          },
          onError: (error, _) {
            state = AsyncValue.error(error, StackTrace.current);
          },
        );

    return UserProfile(
      id: uid,
      name: state.value!.name,
      lastName: state.value!.lastName,
      weight: state.value!.weight,
      height: state.value!.height,
      dateTime: state.value!.dateTime,
    );
  }

  //значения из полей ввода
  Future<void> userUpdate(
    String name,
    String lastName,
    String weight,
    String height,
    DateTime dateTime,
  ) async {
    final uid = state.value?.id;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': name,
      'lastName': lastName,
      'weight': weight,
      'heught': height,
      'dateTime': dateTime,
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
