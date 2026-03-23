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

// Calculate days remaining to exam date
const examDate = new Date('2026-04-07T00:00:00');
const now = new Date();
const daysRemaining = Math.ceil((examDate - now) / (1000 * 60 * 60 * 24));

const message = {
  topic: 'exam_updates',
  notification: {
    title: 'JFT & Skill Form Open Date Reminder',
    body: `${daysRemaining} days remaining until the JFT & Skill exam form opens. Don't miss it!`,
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

admin.messaging().send(message)
  .then((response) => {
    console.log('Notification sent successfully:', response);
    console.log(`Message: "${message.notification.body}"`);
  })
  .catch((error) => {
    console.error('Error sending notification:', error);
  });
