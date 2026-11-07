const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const Razorpay = require("razorpay");

admin.initializeApp();
const db = admin.firestore();

// Lazy initialize Razorpay with environment config
const getRazorpayInstance = () => {
  const key_id = process.env.RAZORPAY_KEY_ID || functions.config().razorpay?.key_id;
  const key_secret = process.env.RAZORPAY_KEY_SECRET || functions.config().razorpay?.key_secret;
  return new Razorpay({ key_id, key_secret });
};

/**
 * 1. Create Razorpay Order
 */
exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required.");
  }

  const { shopId, plan } = data;
  if (!shopId || !plan) {
    throw new functions.https.HttpsError("invalid-argument", "shopId and plan are required.");
  }

  const amountInPaise = plan === "yearly" ? 199900 : 19900; // Rs 1,999 or Rs 199
  const razorpay = getRazorpayInstance();

  try {
    const order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: "INR",
      receipt: `receipt_${shopId}_${Date.now()}`,
      notes: { shopId, plan },
    });
    return { orderId: order.id, amount: order.amount, currency: order.currency };
  } catch (err) {
    throw new functions.https.HttpsError("internal", err.message);
  }
});

/**
 * 2. Razorpay Webhook with Signature Verification & Idempotency
 */
exports.razorpayWebhook = functions.https.onRequest(async (req, res) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET || functions.config().razorpay?.webhook_secret;
  const signature = req.headers["x-razorpay-signature"];

  if (!signature || !secret) {
    return res.status(400).send("Signature or secret missing.");
  }

  // Verify HMAC SHA256 signature
  const expectedSignature = crypto
    .createHmac("sha256", secret)
    .update(JSON.stringify(req.body))
    .digest("hex");

  if (signature !== expectedSignature) {
    console.error("Signature mismatch!");
    return res.status(400).send("Invalid signature.");
  }

  const event = req.body;
  const eventId = event.event_id || req.headers["x-razorpay-event-id"] || `${Date.now()}`;

  // Idempotency check: Ignore duplicate events
  const eventRef = db.collection("webhookEvents").doc(eventId);
  const eventDoc = await eventRef.get();
  if (eventDoc.exists) {
    return res.status(200).send("Event already processed.");
  }

  await eventRef.set({
    eventId,
    event: event.event,
    receivedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const payload = event.payload;

  if (event.event === "payment.captured") {
    const payment = payload.payment.entity;
    const notes = payment.notes || {};
    const shopId = notes.shopId;
    const plan = notes.plan || "monthly";

    if (shopId) {
      const durationDays = plan === "yearly" ? 365 : 30;
      const now = new Date();
      const endDate = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

      await db.collection("subscriptions").doc(shopId).set(
        {
          id: `sub_${shopId}`,
          shopId,
          plan,
          status: "active",
          startDate: admin.firestore.Timestamp.fromDate(now),
          endDate: admin.firestore.Timestamp.fromDate(endDate),
          gracePeriodEndDate: null,
          razorpayPaymentId: payment.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Save payment receipt
      await db.collection("payments").doc(payment.id).set({
        paymentId: payment.id,
        shopId,
        amount: payment.amount / 100,
        status: "success",
        method: payment.method,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  } else if (event.event === "subscription.charged_failed") {
    // 3-Day Grace Period handling
    const subEntity = payload.subscription.entity;
    const notes = subEntity.notes || {};
    const shopId = notes.shopId;

    if (shopId) {
      const graceEnd = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
      await db.collection("subscriptions").doc(shopId).update({
        status: "grace_period",
        gracePeriodEndDate: admin.firestore.Timestamp.fromDate(graceEnd),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  return res.status(200).json({ status: "success" });
});
