const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
const express = require("express");


const app = express();
app.use(express.json());


admin.initializeApp({
  credential: admin.credential.cert(require("../config/firebaseadminsdk.json")),
});


const sendNotification = async (title, body) => {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    topic: "allUsers",
  };

  try {
    await admin.messaging().send(message);
    console.log("Notification sent successfully");
  } catch (error) {
    console.error("Error sending notification:", error);
  }
};


exports.addNotice = functions.firestore
    .document("notices/{noticeId}")
    .onCreate(async (snap) => {
      const noticeData = snap.data();
      const title = noticeData.title;
      const content = noticeData.content;
      const messageTitle = `New Notice: ${title}`;
      const messageBody = content;

      // Send notification
      await sendNotification(messageTitle, messageBody);
    });

// Firestore trigger for adding an event
exports.addEvent = functions.firestore
    .document("events/{eventId}")
    .onCreate(async (snap) => {
      const eventData = snap.data();
      const title = eventData.title;
      const date = eventData.date;
      const messageTitle = `New Event in Calendar: ${date}`;
      const messageBody = title;

      // Send notification
      await sendNotification(messageTitle, messageBody);
    });


const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
