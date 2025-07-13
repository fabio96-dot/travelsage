import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:js/js.dart'; // Import modificato
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; // Percorso relativo corretto

@JS()
external dynamic get context;

class WebConfig {
  static dynamic get jsContext {
    if (kIsWeb) {
      return context;
    }
    return null;
  }

  static FirebaseOptions get firebaseOptions {
    if (!kIsWeb) throw UnsupportedError('Solo per web');
    
    try {
      final config = jsContext['flutterConfig'];
      if (config == null) throw Exception('Config JS mancante');
      
      return FirebaseOptions(
        apiKey: config['apiKey'] as String,
        authDomain: config['authDomain'] as String,
        projectId: config['projectId'] as String,
        storageBucket: config['storageBucket'] as String,
        messagingSenderId: config['messagingSenderId'] as String,
        appId: config['appId'] as String,
        measurementId: config['measurementId'] as String?,
      );
    } catch (e) {
      throw Exception('Errore configurazione web: $e');
    }
  }

  static Future<void> waitForConfig() async {
    if (!kIsWeb) return;

    const maxAttempts = 50;
    int attempts = 0;
    
    while (jsContext['flutterConfig'] == null && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    if (jsContext['flutterConfig'] == null) {
      throw Exception('Configurazione web non caricata entro il timeout');
    }
  }
}