const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
require('dotenv').config();

const stripeSecret = process.env.STRIPE_SECRET_KEY;
if (!stripeSecret) {
  throw new Error('Missing STRIPE_SECRET_KEY in environment configuration.');
}

const stripe = Stripe(stripeSecret);
if (!admin.apps.length) {
  console.log(
    'has FIREBASE_SERVICE_ACCOUNT_JSON:',
    Boolean(process.env.FIREBASE_SERVICE_ACCOUNT_JSON),
  );
  console.log(
    'FIREBASE_SERVICE_ACCOUNT_JSON length:',
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON
      ? process.env.FIREBASE_SERVICE_ACCOUNT_JSON.length
      : 0,
  );
  console.log(
    'GCLOUD_PROJECT:',
    process.env.GCLOUD_PROJECT ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      'missing',
  );

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  } catch (err) {
    console.error('Service account JSON parse error:', err.message);
    throw err;
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
}

const firestore = admin.firestore();
console.log("Firebase project:", admin.app().options.projectId);
const app = express();
app.use(cors({ origin: true }));

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

const jsonParser = express.json();
const rawParser = bodyParser.raw({ type: 'application/json' });

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

app.post('/webhook', rawParser, async (req, res) => {
  if (!webhookSecret) {
    return res
      .status(500)
      .send('Webhook secret is not configured on the server.');
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
        await admin.firestore().collection('payments').doc(uid).set(
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
