import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _cargando = false;

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _iniciarConGoogle() async {
    if (_cargando) return;
    setState(() => _cargando = true);

    try {
      // 1) abre el selector de cuentas de Google
      final cuenta = await GoogleSignIn.instance.authenticate();

      // 2) convierte esa cuenta en una credencial de Firebase
      final credencial = GoogleAuthProvider.credential(
        idToken: cuenta.authentication.idToken,
      );

      // 3) inicia sesión en Firebase; AuthGate detecta el cambio solo
      await FirebaseAuth.instance.signInWithCredential(credencial);
    } on GoogleSignInException catch (e) {
      // si la persona cierra el selector no es un error
      if (e.code != GoogleSignInExceptionCode.canceled) {
        debugPrint('Error Google Sign-In: $e');
        _mensaje('No se pudo iniciar sesión con Google.');
      }
    } catch (e) {
      debugPrint('Error al iniciar sesión: $e');
      _mensaje('No se pudo iniciar sesión. Inténtalo otra vez.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cyclers', style: text.displaySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppGap.related),
              Text(
                'Inicia sesión para continuar',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppGap.nav),
              FilledButton.icon(
                onPressed: _cargando ? null : _iniciarConGoogle,
                icon: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_cargando ? 'Ingresando…' : 'Continuar con Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
