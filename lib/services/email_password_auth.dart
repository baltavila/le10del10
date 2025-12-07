import 'package:firebase_auth/firebase_auth.dart';

class EmailPasswordAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Logica unificada para el boton "Continuar con Email".
  /// - Si el email no existe: crea usuario nuevo (email/password)
  /// - Si el email existe con password: hace login
  /// - Si existe solo con otros proveedores: lanza excepcion con un mensaje claro
  Future<UserCredential> continueWithEmail({
    required String email,
    required String password,
  }) async {
    email = email.trim();

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Ingresa un email y una contrasena.');
    }

    try {
      // Consultar metodos de ingreso para este email
      final methods = await _auth.fetchSignInMethodsForEmail(email);

      // CASO A: no hay ningun usuario con ese email -> registro
      if (methods.isEmpty) {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Opcional: enviar mail de verificacion
        await cred.user?.sendEmailVerification();

        return cred;
      }

      // CASO B: ya existe usuario con password -> login
      if (methods.contains('password')) {
        try {
          final cred = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          return cred;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
            throw Exception('La contrasena no coincide con este email.');
          }
          rethrow;
        }
      }

      // CASO C: email registrado solo con otros proveedores (Google/Facebook, etc.)
      final pretty = methods.join(', ');
      throw Exception(
        'Este email ya esta registrado usando: $pretty.\n'
        'Usa el boton correspondiente (Google/Facebook) para ingresar.',
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('El email no es valido.');
        case 'weak-password':
          throw Exception('La contrasena es demasiado debil.');
        case 'operation-not-allowed':
          throw Exception(
              'El login con email/contrasena no esta habilitado en Firebase.');
        default:
          throw Exception('Ocurrio un error. Proba nuevamente. (${e.code})');
      }
    }
  }
}
