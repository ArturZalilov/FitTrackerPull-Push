import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  //регистрация
  Future<void> signUp({required String email, required String password}) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    //здесь должно открываться новое окно и вызываться метод добавления данных нового пользователя
  }

  //вход
  Future<void> signIn({required String email, required String password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //выход
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  //метод состояния пользователя (вошел/вышел)
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  //какой пользователь вошёл
  String? get currentUserId => _firebaseAuth.currentUser?.uid;
}
