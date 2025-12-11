import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/payment_service.dart';

class PaymentRequiredPage extends StatefulWidget {
  final User user;

  const PaymentRequiredPage({super.key, required this.user});

  @override
  State<PaymentRequiredPage> createState() => _PaymentRequiredPageState();
}

class _PaymentRequiredPageState extends State<PaymentRequiredPage> {
  final PaymentService _paymentService = PaymentService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _paymentSubscription;

  bool _loading = false;
  bool _waitingForConfirmation = false;
  bool _navigated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listenToPaymentStatus();
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _paymentService.dispose();
    super.dispose();
  }

  void _listenToPaymentStatus() {
    final docRef = FirebaseFirestore.instance
        .collection('payments')
        .doc(widget.user.uid);

    _paymentSubscription = docRef.snapshots().listen(
      (doc) {
        final data = doc.data();
        final status = data?['status'] as String? ?? 'unpaid';

        if (status == 'paid') {
          _handlePaymentConfirmed();
        } else {
          if (mounted) {
            setState(() {
              _waitingForConfirmation = _loading;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('Error escuchando pagos: $error');
      },
    );
  }

  Future<void> _handlePaymentConfirmed() async {
    if (!mounted || _navigated) return;

    setState(() {
      _waitingForConfirmation = false;
    });

    // Compatibilidad opcional: marcar premium en users/{uid}
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({'premium': true}, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('No se pudo marcar premium: $e\n$st');
    }

    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false);
  }

  Future<void> _startCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
      _waitingForConfirmation = true;
    });

    try {
      final checkoutUrl =
          await _paymentService.createCheckoutSession(uid: widget.user.uid);
      await _paymentService.openCheckoutUrl(checkoutUrl);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/portada', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago requerido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: _loading ? null : _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Necesitas completar el pago para ingresar al menu principal.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Toca "Comprar acceso por €7".\n'
              '2. Se abrira Stripe Checkout en el navegador.\n'
              '3. Una vez confirmado el pago y la pagina muestre '
              '"Pago confirmado", regresa a la app.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Comprar acceso por €7'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu usuario quedara desbloqueado automaticamente cuando Stripe '
              'notifique el pago. Este proceso puede tardar unos segundos.',
            ),
            if (_waitingForConfirmation) ...[
              const SizedBox(height: 16),
              Row(
                children: const [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esperando confirmacion del pago...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
