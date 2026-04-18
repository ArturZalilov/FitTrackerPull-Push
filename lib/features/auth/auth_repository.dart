import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  //регистрация
  Future signUp({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required String weight,
    required String height,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ✅ Добавь это:
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
          'name': name,
          'lastName': lastName,
          'weight': weight,
          'height': height,
        });
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
