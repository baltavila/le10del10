const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');
const { MercadoPagoConfig, Preference, Payment } = require('mercadopago');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
require('dotenv').config();

const stripeSecret = process.env.STRIPE_SECRET_KEY;
if (!stripeSecret) {
  throw new Error('Missing STRIPE_SECRET_KEY in environment configuration.');
}

const stripe = Stripe(stripeSecret);
const mpAccessToken = process.env.MP_ACCESS_TOKEN;
if (!mpAccessToken) {
  throw new Error('Missing MP_ACCESS_TOKEN in environment configuration.');
}
const mpClient = new MercadoPagoConfig({
  accessToken: mpAccessToken,
});
const mpPreference = new Preference(mpClient);
const mpPayment = new Payment(mpClient);

let firestore;
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
const hasServiceAccount =
  typeof serviceAccountJson === 'string' && serviceAccountJson.trim().length > 0;

if (!admin.apps.length) {
  if (hasServiceAccount) {
    console.log('has FIREBASE_SERVICE_ACCOUNT_JSON:', true);
    console.log('FIREBASE_SERVICE_ACCOUNT_JSON length:', serviceAccountJson.length);
    console.log(
      'GCLOUD_PROJECT:',
      process.env.GCLOUD_PROJECT ||
        process.env.GOOGLE_CLOUD_PROJECT ||
        'missing',
    );

    let serviceAccount;
    try {
      serviceAccount = JSON.parse(serviceAccountJson);
    } catch (err) {
      console.error('Service account JSON parse error:', err.message);
      throw err;
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
    firestore = admin.firestore();
    console.log('Firebase project:', admin.app().options.projectId);
  } else {
    console.log('Firebase disabled locally');
  }
} else {
  firestore = admin.firestore();
  console.log('Firebase project:', admin.app().options.projectId);
}
const app = express();

const PRICE_ID =
  process.env.STRIPE_PRICE_ID || 'price_1SUPoC0gHm7588JBwmURM2tn';
const PRODUCT_ID =
  process.env.STRIPE_PRODUCT_ID || 'prod_TRlOBJq9wPumoW';
const SUCCESS_URL =
  process.env.SUCCESS_URL ||
  'https://example.com/checkout-success?session_id={CHECKOUT_SESSION_ID}&return_to_app=true';
const CANCEL_URL =
  process.env.CANCEL_URL || 'https://example.com/checkout-cancel';
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
const MP_SUCCESS_URL = 'https://example.com/success';
const MP_FAILURE_URL = 'https://example.com/failure';
const MP_PENDING_URL = 'https://example.com/pending';

const jsonParser = express.json();
const rawParser = bodyParser.raw({ type: 'application/json' });

app.use((req, res, next) => {
  if (req.originalUrl === '/webhook') {
    return next();
  }
  return jsonParser(req, res, next);
});
app.use(cors({ origin: true }));

const appendReturnToApp = (targetUrl) => {
  if (targetUrl.includes('return_to_app')) {
    return targetUrl;
  }
  const glue = targetUrl.includes('?') ? '&' : '?';
  return `${targetUrl}${glue}return_to_app=true`;
};

const successUrlWithSession = () => {
  if (SUCCESS_URL.includes('{CHECKOUT_SESSION_ID}')) {
    return appendReturnToApp(SUCCESS_URL);
  }

  const glue = SUCCESS_URL.includes('?') ? '&' : '?';
  return appendReturnToApp(
    `${SUCCESS_URL}${glue}session_id={CHECKOUT_SESSION_ID}`,
  );
};

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.get('/debug/firestore', async (_req, res) => {
  if (!firestore) {
    return res
      .status(503)
      .json({ error: 'Firebase is disabled; Firestore not available.' });
  }

  try {
    await firestore.collection('debug').doc('ping').set({
      ok: true,
      at: Date.now(),
    });
    return res.json({ ok: true });
  } catch (error) {
    console.error('Debug firestore write failed', error);
    return res.status(500).json({ ok: false, error: error.message });
  }
});

app.post('/create-checkout-session', jsonParser, async (req, res) => {
  const { uid, priceId } = req.body || {};

  if (!uid) {
    return res.status(400).json({ error: 'Missing uid in request body.' });
  }

  const selectedPrice = priceId || PRICE_ID;

  try {
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      payment_method_types: ['card'],
      line_items: [
        {
          price: selectedPrice,
          quantity: 1,
        },
      ],
      success_url: successUrlWithSession(),
      cancel_url: CANCEL_URL,
      client_reference_id: uid,
      metadata: {
        uid: uid,
        priceId: selectedPrice,
        productId: PRODUCT_ID,
      },
    });

    return res.json({ url: session.url });
  } catch (error) {
    console.error('Error creating checkout session', error);
    return res
      .status(500)
      .json({ error: 'Unable to create checkout session.' });
  }
});

app.post('/mp/create-preference', async (req, res) => {
  const { uid, email } = req.body || {};

  if (!uid || !email) {
    return res
      .status(400)
      .json({ error: 'Missing uid or email in request body.' });
  }

  try {
    const preferenceResponse = await mpPreference.create({
      body: {
        items: [
          {
            title: 'Acceso App-Album Le 10 del 10',
            quantity: 1,
            unit_price: 10000,
            currency_id: 'ARS',
          },
        ],
        external_reference: uid,
        metadata: { uid, email },
        payer: { email },
        back_urls: {
          success: MP_SUCCESS_URL,
          failure: MP_FAILURE_URL,
          pending: MP_PENDING_URL,
        },
        auto_return: 'approved',
      },
    });

    return res.json({
      init_point: preferenceResponse?.init_point,
      sandbox_init_point: preferenceResponse?.sandbox_init_point,
      preference_id: preferenceResponse?.id,
    });
  } catch (error) {
    console.error('Error creating Mercado Pago preference', error);
    return res.status(500).json({
      error: 'Unable to create Mercado Pago preference.',
    });
  }
});

app.post('/mp/webhook', async (req, res) => {
  if (!firestore) {
    return res
      .status(503)
      .json({ error: 'Firebase is disabled; Firestore not available.' });
  }

  const paymentId = req.body?.data?.id || req.body?.id;

  if (!paymentId) {
    console.log('MP webhook received without payment id');
    return res.status(200).json({ received: true });
  }

  try {
    const paymentResponse = await mpPayment.get({ id: paymentId });
    const paymentData = paymentResponse?.body || paymentResponse;
    const status = paymentData?.status;
    const uid =
      paymentData?.external_reference || paymentData?.metadata?.uid;

    if (status === 'approved' && uid) {
      await firestore.collection('payments').doc(uid).set(
        {
          status: 'paid',
          premium: true,
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          provider: 'mercadopago',
          mpPaymentId: paymentId,
        },
        { merge: true },
      );
      console.log('MP payment approved and recorded', {
        paymentId,
        uid,
      });
    } else {
      console.log('MP payment not recorded', {
        paymentId,
        status,
        hasUid: Boolean(uid),
      });
    }
  } catch (error) {
    console.error('Error handling MP webhook', {
      paymentId,
      message: error.message,
    });
  }

  return res.status(200).json({ received: true });
});

app.post('/webhook', rawParser, async (req, res) => {
  if (!webhookSecret) {
    return res
      .status(500)
      .send('Webhook secret is not configured on the server.');
  }

  if (!firestore) {
    return res
      .status(503)
      .send('Firebase is disabled; Firestore not available.');
  }

  const signature = req.headers['stripe-signature'];

  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      signature,
      webhookSecret,
    );
  } catch (err) {
    console.error('Webhook signature verification failed.', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const uid = session.metadata?.uid;

    if (!uid) {
      console.error(
        'checkout.session.completed event received without uid metadata.',
      );
    } else {
      try {
        await firestore.collection('payments').doc(uid).set(
          {
            status: 'paid',
            stripeSessionId: session.id,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        console.log('Payment marked as paid for uid:', uid);

        await firestore.collection('users').doc(uid).set(
          {
            premium: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      } catch (firestoreError) {
        console.error('Failed to write payment document', firestoreError);
        return res.status(500).json({ error: 'Firestore write failed' });
      }
    }
  }

  res.json({ received: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Stripe backend listening on port ${PORT}`);
});

module.exports = app;
