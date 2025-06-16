const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")("sk_test_51RSzAnFHNqUk7cFRthgWdu0u61q8GuE4PHDRMMRsX0DU8bsyR3PaL6Lbqhw1wDcsYXPMGYspboEfXvoi9o893qGa00qvsUXmVw");
admin.initializeApp();

// ✅ 1. Create PRO subscription
exports.createProSubscription = functions.https.onCall(async (data, context) => {
  const { email, name, paymentMethodId, state, uid } = data;

  try {
    // 1. Create Stripe customer
    const customer = await stripe.customers.create({
      email,
      name,
      payment_method: paymentMethodId,
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    });

    // 2. Check if first 1000 PROs in state
    let coupon = null;
    const snapshot = await admin.firestore()
      .collection('drivers')
      .where('state', '==', state)
      .where('isPro', '==', true)
      .get();

    if (snapshot.size < 1000) {
      coupon = 'FIRST1000FREE6MONTHS'; // Replace with actual coupon ID
    }

    // 3. Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: "PRO_Driver_Membership" }], // Replace with your actual price ID
      coupon: coupon,
      expand: ["latest_invoice.payment_intent"],
    });

    // 4. Save customer & subscription in Firestore
    await admin.firestore().collection('drivers').doc(uid).update({
      stripeCustomerId: customer.id,
      stripeSubscriptionId: subscription.id,
      isPro: true,
      subscriptionStatus: subscription.status,
    });

    return {
      success: true,
      customerId: customer.id,
      subscriptionId: subscription.id,
      status: subscription.status,
    };
  } catch (error) {
    console.error("Stripe error:", error);
    return { success: false, error: error.message };
  }
});

// ✅ 2. Cancel PRO subscription manually
exports.cancelProSubscription = functions.https.onCall(async (data, context) => {
  const { subscriptionId, uid } = data;

  try {
    await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true,
    });

    await admin.firestore().collection('drivers').doc(uid).update({
      subscriptionStatus: 'canceled',
    });

    return { success: true };
  } catch (error) {
    console.error("Cancel error:", error);
    return { success: false, error: error.message };
  }
});

// ✅ 3. Stripe webhook to suspend account if payment fails
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = 'whsec_0dz1rV5McPyB7jRI95ZQo6SP0LlQPbzE'; // Replace with your real webhook secret

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error("Webhook signature failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'invoice.payment_failed') {
    const customerId = event.data.object.customer;

    const snapshot = await admin.firestore()
      .collection('drivers')
      .where('stripeCustomerId', '==', customerId)
      .get();

    for (const doc of snapshot.docs) {
      await doc.ref.update({
        isPro: false,
        subscriptionStatus: 'suspended',
      });
    }

    console.log(`Driver account suspended due to failed payment for customer ${customerId}`);
  }

  res.json({ received: true });
});

// ✅ 4. Create Stripe Customer Portal session
exports.createStripeCustomerPortal = functions.https.onCall(async (data, context) => {
  const { uid, email } = data;

  if (!uid || !email) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing user ID or email.');
  }

  try {
    const userDoc = await admin.firestore().collection('drivers').doc(uid).get();
    const customerId = userDoc.data()?.stripeCustomerId;

    if (!customerId) {
      throw new Error('Stripe customer ID not found.');
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: 'https://www.thedeliverytruck.com/driver_home', // Update as needed
    });

    return { url: session.url };
  } catch (error) {
    console.error('Customer portal error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});