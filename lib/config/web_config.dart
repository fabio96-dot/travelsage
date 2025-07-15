import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebConfig {
  static FirebaseOptions get firebaseOptions {
    return const FirebaseOptions(
      apiKey: "AIzaSyDbmXGUoGFCDheDVTj0hw-wcyMPw98w23E",
      authDomain: "travelsage-2fbbc.firebaseapp.com",
      projectId: "travelsage-2fbbc",
      storageBucket: "travelsage-2fbbc.appspot.com",
      messagingSenderId: "1051759939227",
      appId: "1:1051759939227:web:b34f7d629a4d79935d003e",
      measurementId: "G-RJZKZXNDNW",
    );
  }

  static Future<void> waitForConfig() async {
    // Non serve più attendere, la config è hardcoded
    await Future.delayed(Duration.zero);
  }
}