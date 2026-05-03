import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/core/theme_provider.dart';
import 'package:e_guru/features/admin/admin_home_page.dart';
import 'package:e_guru/features/auth/login_page.dart';
import 'package:e_guru/features/student/student_home_page.dart';
import 'package:e_guru/features/teacher/teacher_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:e_guru/core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const ProviderScope(child: EGuruApp()));
}

class EGuruApp extends ConsumerWidget {
  const EGuruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Trigger FCM Setup reliably
    session.whenData((user) {
      if (user != null) {
        Future.microtask(() {
          final notifService = ref.read(notificationServiceProvider);
          notifService.requestPermission();
          notifService.uploadFcmToken();
        });
      }
    });

    return MaterialApp(
      title: 'e_guru',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: session.when(
        data: (value) {
          if (value == null) return const LoginPage();

          if (value.role == 'admin') return const AdminHomePage();
          if (value.role == 'teacher') return const TeacherHomePage();
          return const StudentHomePage();
        },
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Error. Restart app.'))),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
