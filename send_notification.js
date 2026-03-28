#!/usr/bin/env node
/**
 * Send a push notification to all app users via FCM topic.
 *
 * Setup:
 *   npm install firebase-admin
 *
 * Usage:
 *   node send_notification.js
 *
 * Requirements:
 *   - Place your Firebase service account key as serviceAccountKey.json
 *     (Download from Firebase Console > Project Settings > Service accounts)
 */

const admin = require('firebase-admin');

// Prefer credentials supplied via environment variable to avoid storing
// the service account key file on disk alongside the script.
//
// Option A (recommended): Set GOOGLE_APPLICATION_CREDENTIALS to the path of
//   the service account JSON file, then firebase-admin picks it up automatically.
// Option B: Set SERVICE_ACCOUNT_JSON to the raw JSON content of the key file.
// Option C (fallback): Place serviceAccountKey.json next to this script.
// Credentials must be supplied via environment variable.
// Option A (recommended): Set SERVICE_ACCOUNT_JSON to the raw JSON of the key.
// Option B: Set GOOGLE_APPLICATION_CREDENTIALS to the file path of the key.
// Never store serviceAccountKey.json on disk or commit it to source control.
let credential;
if (process.env.SERVICE_ACCOUNT_JSON) {
  const serviceAccount = JSON.parse(process.env.SERVICE_ACCOUNT_JSON);
  credential = admin.credential.cert(serviceAccount);
} else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  credential = admin.credential.applicationDefault();
} else {
  console.error(
    'Error: No Firebase credentials found.\n' +
    'Set SERVICE_ACCOUNT_JSON or GOOGLE_APPLICATION_CREDENTIALS environment variable.'
  );
  process.exit(1);
}

admin.initializeApp({ credential });

const db = admin.firestore();

async function sendNotification() {
  // Fetch exam date from Firestore
  const doc = await db.collection('config').doc('examDate').get();
  if (!doc.exists) {
    console.error('Exam date not found in Firestore.');
    process.exit(1);
  }

  const data = doc.data();
  const examDate = data.date.toDate ? data.date.toDate() : new Date(data.date);
  const now = new Date();
  const totalMs = examDate - now;

  const totalMinutes = Math.floor(totalMs / (1000 * 60));
  const totalHours = Math.floor(totalMs / (1000 * 60 * 60));
  const days = Math.floor(totalMs / (1000 * 60 * 60 * 24));
  const hours = Math.floor((totalMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((totalMs % (1000 * 60 * 60)) / (1000 * 60));

  let countdownText;
  if (totalMs <= 0) {
    countdownText = 'The form is now open!';
  } else if (days > 0) {
    countdownText = `${days}d ${hours}h ${minutes}m remaining`;
  } else if (totalHours > 0) {
    countdownText = `${totalHours}h ${minutes}m remaining`;
  } else {
    countdownText = `${totalMinutes}m remaining`;
  }

  console.log(`Exam date from Firestore: ${examDate}`);
  console.log(`Countdown: ${countdownText}`);

  const message = {
    topic: 'exam_updates',
    notification: {
      title: 'JFT & Skill Form Open Date Reminder',
      body: `${countdownText} until the JFT & Skill exam form opens. Don't miss it!`,
    },
    data: {
      title: 'JFT & Skill Form Open Date Reminder',
      body: `${countdownText} until the JFT & Skill exam form opens. Don't miss it!`,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'exam_updates',
        sound: 'default',
        priority: 'high',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
      },
      payload: {
        aps: {
          sound: 'default',
          'content-available': 1,
        },
      },
    },
  };

  const response = await admin.messaging().send(message);
  console.log('Notification sent successfully:', response);
  console.log(`Message: "${message.notification.body}"`);
}

sendNotification().catch((error) => {
  console.error('Error sending notification:', error);
  process.exit(1);
});
