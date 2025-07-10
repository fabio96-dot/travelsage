importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: self.flutterConfig.FIREBASE_API_KEY,
  appId: self.flutterConfig.FIREBASE_APP_ID,
  projectId: self.flutterConfig.FIREBASE_PROJECT_ID,
  storageBucket: self.flutterConfig.FIREBASE_STORAGE_BUCKET
});