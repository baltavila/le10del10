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
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
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
            tooltip: 'Cerrar sesión',
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
              'Necesitás completar el pago para ingresar al menú principal.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Tocá “Comprar acceso por €7”.\n'
              '2. Se abrirá Stripe Checkout en el navegador.\n'
              '3. Una vez confirmado el pago y la página muestre '
              '“Pago confirmado”, regresá a la app.',
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
              'Tu usuario quedará desbloqueado automáticamente cuando Stripe '
              'notifique el pago. Este proceso puede tardar unos segundos.',
            ),
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
