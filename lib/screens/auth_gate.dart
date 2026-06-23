import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// импортируй свои экраны
import 'auth_screen.dart';
import 'MainScreen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // ⏳ пока грузится
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ если пользователь есть → в Main
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // ❌ если нет → на авторизацию
        return const AuthScreen();
      },
    );
  }
}