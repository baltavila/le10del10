import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _loadingEmail = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapFirebaseError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'El email no es válido';
      case 'missing-email':
        return 'Ingresá tu email.';
      case 'missing-password':
        return 'Ingresá tu contraseña.';
      case 'weak-password':
        return 'La contraseña es demasiado corta';
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return 'Este email ya está en uso con otro método de inicio';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Ocurrió un error, intentá nuevamente';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return cred;
    } catch (e) {
      debugPrint("Error Google login: $e");
      return null;
    }
  }

  Future<void> signInWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Ingresá tu email y contraseña.');
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await _registerAndSignIn(email, password);
      } else {
        _showMessage(_mapFirebaseError(e));
      }
    } catch (_) {
      _showMessage('Ocurrió un error, intentá nuevamente');
    }
  }

  Future<void> _registerAndSignIn(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapFirebaseError(e));
    } catch (_) {
      _showMessage('Ocurrió un error, intentá nuevamente');
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetController =
        TextEditingController(text: emailController.text.trim());
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Olvidaste tu contraseña?'),
          content: TextField(
            controller: resetController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final email = resetController.text.trim();
                if (email.isEmpty) {
                  _showMessage('Ingresá tu email.');
                  return;
                }
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  _showMessage(
                      'Te enviamos un email para restablecer tu contraseña.');
                } on FirebaseAuthException catch (e) {
                  _showMessage(_mapFirebaseError(e));
                } catch (_) {
                  _showMessage('Ocurrió un error, intentá nuevamente');
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
    resetController.dispose();
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.token);
        final userCred = await _auth.signInWithCredential(credential);
        return userCred;
      } else if (result.status == LoginStatus.cancelled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inicio de sesión cancelado')),
          );
        }
        return null;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Facebook error: ${result.message ?? 'desconocido'}')),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook error: $e')),
        );
      }
      return null;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onContinueWithEmailPressed() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Completa email y contrasena');
      return;
    }

    setState(() => _loadingEmail = true);
    var success = false;

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      success = true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        try {
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          success = true;
        } on FirebaseAuthException catch (createError) {
          debugPrint('Error registrando usuario: $createError');
          _showMessage('Ocurrio un error, proba nuevamente.');
        } catch (e, st) {
          debugPrint('Error desconocido al registrar: $e\n$st');
          _showMessage('Ocurrio un error, proba nuevamente.');
        }
      } else if (e.code == 'wrong-password') {
        _showMessage('Contrasena incorrecta.');
      } else {
        debugPrint('Error al iniciar sesion: $e');
        _showMessage('Ocurrio un error, proba nuevamente.');
      }
    } catch (e, st) {
      debugPrint('Error inesperado en login: $e\n$st');
      _showMessage('Ocurrio un error, proba nuevamente.');
    } finally {
      setState(() => _loadingEmail = false);
    }

    // La navegacion la maneja AuthGate escuchando authStateChanges(),
    // no hagas nada mas aca salvo que ya tengas logica existente.
    if (success) {
      // Si hay navegaciボn especボfica, agregala aquボ. Caso contrario,
      // AuthGate se encarga al detectar el usuario autenticado.
    }
  }

  @override
  Widget build(BuildContext context) {
    const celeste = Color(0xFF00B0FF);
    const celesteClaro = Color(0xFFB3E5FC);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/portada.PNG'),
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bienvenido a Le 10 del 10',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF80D8FF),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email/Nuevo Email',
                      hintStyle: const TextStyle(color: celesteClaro),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña/Nueva contraseña ',
                      hintStyle: const TextStyle(color: celesteClaro),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  // Botón Email (celeste)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: celeste,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loadingEmail ? null : _onContinueWithEmailPressed,
                      child: _loadingEmail
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continuar con Email',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),

                  const SizedBox(height: 14),

                  // Botón Google (celeste)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: celeste,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        await signInWithGoogle();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ingresar con Google',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botón Facebook (celeste)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: celeste,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        await signInWithFacebook();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.facebook, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ingresar con Facebook',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
