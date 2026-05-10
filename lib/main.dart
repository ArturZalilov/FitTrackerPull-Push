import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/main_layout.dart';
import 'features/workouts/screens/select_exercise_screen.dart';
import 'features/workouts/screens/workout_detail_screen.dart';
import 'features/exercises/screens/create_exercise_screen.dart';
import 'features/exercises/screens/exercise_progress_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Заблокировать только портретную ориентацию
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: FitTrackApp()));
}

class FitTrackApp extends ConsumerWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Pull&Push',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/app': (context) => const MainLayout(),

        // ✅ Унифицированный маршрут для тренировки:
        '/workout-detail': (context) {
          final workoutId =
              ModalRoute.of(context)?.settings.arguments as String?;
          return WorkoutDetailScreen(workoutId: workoutId);
        },
        // ✅ НОВЫЙ МАРШРУТ:
        '/select-exercise': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;

          return SelectExerciseScreen(
            workoutId: args?['workoutId'] as String,
            existingExerciseCodes: args?['existingCodes'] != null
                ? List<String>.from(args!['existingCodes'])
                : [],
          );
        },

        // ✅ УБРАЛИ workoutId - экран сам прочитает из arguments
        '/create-exercise': (context) => const CreateExerciseScreen(),

        '/exercise-sets': (context) => const Scaffold(),

        // ✅ УБРАЛИ exerciseId - экран сам прочитает из arguments
        '/exercise-progress': (context) => const ExerciseProgressScreen(),
      },
    );
  }
}
