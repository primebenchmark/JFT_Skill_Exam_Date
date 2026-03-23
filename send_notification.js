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
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

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
    android: {
      notification: {
        channelId: 'exam_updates',
        sound: 'default',
        priority: 'high',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
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
