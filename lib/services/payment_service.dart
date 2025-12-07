import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Handles all communications with the payment backend + Stripe Checkout.
class PaymentService {
  static const String _backendBaseUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String priceId = 'price_1SUPoC0gHm7588JBwmURM2tn';

  final http.Client _client;

  PaymentService({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildEndpoint(String path) {
    final normalizedBase = _backendBaseUrl.endsWith('/')
        ? _backendBaseUrl.substring(0, _backendBaseUrl.length - 1)
        : _backendBaseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBase/$normalizedPath');
  }

  Future<String> createCheckoutSession({required String uid}) async {
    final response = await _client.post(
      _buildEndpoint('/create-checkout-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'priceId': priceId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo generar la sesión de pago (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final checkoutUrl = decoded['url'] as String?;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('Respuesta inválida del backend de pagos.');
    }

    return checkoutUrl;
  }

  Future<void> openCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception('No se pudo abrir la URL de Stripe Checkout.');
    }
  }

  void dispose() {
    _client.close();
  }
}
