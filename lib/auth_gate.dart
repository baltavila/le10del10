import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'main.dart';
import 'screens/payment_required_page.dart';
import 'screens/payment_success_page.dart';

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

enum _PaymentState { loading, unpaid, awaitingConfirmation, paid, error }

class PaymentAccessGate extends StatefulWidget {
  final User user;

  const PaymentAccessGate({super.key, required this.user});

  @override
  State<PaymentAccessGate> createState() => _PaymentAccessGateState();
}

class _PaymentAccessGateState extends State<PaymentAccessGate> {
  static const int _defaultAmount = 700;
  static const String _defaultPriceId = 'price_1SUPoC0gHm7588JBwmURM2tn';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  _PaymentState _state = _PaymentState.loading;
  Map<String, dynamic>? _paymentData;
  String? _pendingSessionId;
  String? _errorMessage;

  String get _prefsKey => 'payment_session_ack_${widget.user.uid}';

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
      _paymentData = null;
      _pendingSessionId = null;
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
        _paymentData = null;
        _pendingSessionId = null;
      });
      return;
    }

    final data = doc.data()!;
    final status = data['status'] as String? ?? 'unpaid';
    _paymentData = data;

    if (status != 'paid') {
      setState(() {
        _state = _PaymentState.unpaid;
        _pendingSessionId = null;
      });
      return;
    }

    final sessionId = (data['sessionId'] as String?) ?? '';
    if (sessionId.isEmpty) {
      setState(() {
        _state = _PaymentState.paid;
        _pendingSessionId = null;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final acknowledgedSession = prefs.getString(_prefsKey);

    if (acknowledgedSession == sessionId) {
      if (!mounted) return;
      setState(() {
        _state = _PaymentState.paid;
        _pendingSessionId = sessionId;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _state = _PaymentState.awaitingConfirmation;
        _pendingSessionId = sessionId;
      });
    }
  }

  Future<void> _markPaymentAsViewed() async {
    final sessionId = _pendingSessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, sessionId);
    }

    if (!mounted) return;
    setState(() {
      _state = _PaymentState.paid;
    });

    if (!mounted) return;
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
      case _PaymentState.awaitingConfirmation:
        final amount =
            (_paymentData?['amount'] as num?)?.toInt() ?? _defaultAmount;
        final priceId =
            (_paymentData?['priceId'] as String?) ?? _defaultPriceId;
        return PaymentSuccessPage(
          amount: amount,
          priceId: priceId,
          onEnter: _markPaymentAsViewed,
        );
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
