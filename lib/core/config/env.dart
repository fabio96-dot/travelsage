import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _getWebVar(String key) => 
      js.context['flutterConfig'][key] ?? '';

  static Future<void> load() async {
    if (kIsWeb) return; // Web usa env.js
    await dotenv.load(fileName: '.env');
  }

  static String get firebaseApiKey => 
      kIsWeb ? _getWebVar('FIREBASE_API_KEY') : dotenv.env['FIREBASE_API_KEY']!;

  static String get firebaseAppId => 
      kIsWeb ? _getWebVar('FIREBASE_APP_ID') : dotenv.env['FIREBASE_APP_ID']!;


 static String get firebaseProjectId =>
      kIsWeb ? _getWebVar('FIREBASE_PROJECT_ID') : dotenv.env['FIREBASE_PROJECT_ID']!;

  static String get firebaseMessagingSenderId =>
      kIsWeb ? _getWebVar('FIREBASE_MESSAGING_SENDER_ID') : dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!;

  static String get firebaseStorageBucket =>
      kIsWeb ? _getWebVar('FIREBASE_STORAGE_BUCKET') : dotenv.env['FIREBASE_STORAGE_BUCKET']!;
}
