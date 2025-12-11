import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';
import 'main.dart';
import 'screens/payment_required_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return PaymentAccessGate(user: user);
        }

        return const LoginPage();
      },
    );
  }
}

enum _PaymentState { loading, unpaid, paid, error }

class PaymentAccessGate extends StatefulWidget {
  final User user;

  const PaymentAccessGate({super.key, required this.user});

  @override
  State<PaymentAccessGate> createState() => _PaymentAccessGateState();
}

class _PaymentAccessGateState extends State<PaymentAccessGate> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  _PaymentState _state = _PaymentState.loading;
  String? _errorMessage;
  bool _navigatedToMenu = false;

  @override
  void initState() {
    super.initState();
    _subscribeToPayments();
  }

  @override
  void didUpdateWidget(covariant PaymentAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _subscription?.cancel();
      _state = _PaymentState.loading;
      _navigatedToMenu = false;
      _subscribeToPayments();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToPayments() {
    final docRef =
        FirebaseFirestore.instance.collection('payments').doc(widget.user.uid);

    _subscription = docRef.snapshots().listen(
      (doc) => _handlePaymentDoc(doc),
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _state = _PaymentState.error;
          _errorMessage = error.toString();
        });
      },
    );
  }

  Future<void> _handlePaymentDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (!mounted) return;

    if (!doc.exists || doc.data() == null) {
      setState(() {
        _state = _PaymentState.unpaid;
        _errorMessage = null;
      });
      return;
    }

    final data = doc.data()!;
    final status = data['status'] as String? ?? 'unpaid';
    if (status == 'paid') {
      await _markPaymentAsPaid();
    } else {
      setState(() {
        _state = _PaymentState.unpaid;
        _errorMessage = null;
      });
    }
  }

  Future<void> _markPaymentAsPaid() async {
    if (!mounted || _navigatedToMenu) return;
    setState(() {
      _state = _PaymentState.paid;
    });

    // Compatibilidad: opcionalmente marcar premium en users/{uid}
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({'premium': true}, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('No se pudo marcar premium en users: $e\n$st');
    }

    if (!mounted || _navigatedToMenu) return;
    _navigatedToMenu = true;
    Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _PaymentState.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case _PaymentState.unpaid:
        return PaymentRequiredPage(user: widget.user);
      case _PaymentState.paid:
        return const MenuScreen();
      case _PaymentState.error:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo verificar el estado del pago.',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Intentalo nuevamente en unos minutos.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _state = _PaymentState.loading;
                        _errorMessage = null;
                      });
                      _subscription?.cancel();
                      _subscribeToPayments();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
