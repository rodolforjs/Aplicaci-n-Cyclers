import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

// Decide qué pantalla mostrar según si hay una sesión iniciada.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  // pantalla que se muestra cuando ya hay sesión (en nuestra app, HomeScreen)
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // emite un valor cada vez que alguien inicia o cierra sesión
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // mientras Firebase revisa si hay sesión guardada
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // hay usuario: entra a la app
        if (snapshot.hasData) return child;

        // no hay usuario: pide iniciar sesión
        return const LoginScreen();
      },
    );
  }
}
