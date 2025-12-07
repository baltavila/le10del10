import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  final int amount;
  final String priceId;
  final VoidCallback onEnter;

  const PaymentSuccessPage({
    super.key,
    required this.amount,
    required this.priceId,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount =
        (amount / 100).toStringAsFixed(2).replaceAll('.', ',');

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 96),
              const SizedBox(height: 24),
              const Text(
                '✔ Pago confirmado',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Recibimos tu aporte de €$formattedAmount.\n'
                'Referencia: $priceId',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onEnter,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
