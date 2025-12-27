import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/messaging_service.dart';
import 'app_shell.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (user == null) {
          return const SignInScreen();
        }

        // Ensure user doc exists (best-effort).
        final db = context.read<FirestoreService>();
        final msg = context.read<MessagingService>();

        final name = user.displayName ?? 'Gebruiker';
        final email = user.email ?? '';
        db.upsertUser(uid: user.uid, name: name, email: email);
        msg.initForUser(user.uid);

        return const AppShell();
      },
    );
  }
}
