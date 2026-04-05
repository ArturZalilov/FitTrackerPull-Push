import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

//доступ к Repository авторизации (для получения uid и состояния авторизации)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

//состояние пользователя (вошел/вышел)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

//нажатие кнопок
class AuthNotifier extends Notifier<void> {
  late AuthRepository _repo;
  @override
  void build() {
    _repo = ref.read(authRepositoryProvider);
  }

  //вход
  Future<void> signIn(String email, String password) async {
    await _repo.signIn(email: email, password: password);
  }

  //регистрация
  Future<void> signUp(String email, String password) async {
    await _repo.signUp(email: email, password: password);
  }

  //выход
  Future<void> signOut() async {
    await _repo.signOut();
  }
}
