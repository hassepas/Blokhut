import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/messaging_service.dart';
import 'services/timer_controller.dart';
import 'theme/studybuddy_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StudyBuddyApp());
}

class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<MessagingService>(create: (_) => MessagingService()),
        ChangeNotifierProvider<TimerController>(create: (_) => TimerController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StudyBuddy',
        theme: StudyBuddyTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
