// lib/config/mobile_config.dart
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';  // Assicurati che il percorso sia corretto

/// Versione mobile della configurazione
class WebConfig {
  /// Restituisce sempre null su mobile
  static dynamic get jsContext => null;

  /// Restituisce le opzioni Firebase predefinite per la piattaforma corrente
  static FirebaseOptions get firebaseOptions => 
      DefaultFirebaseOptions.currentPlatform;

  /// No-op su mobile (non serve attendere il caricamento JS)
  static Future<void> waitForConfig() async => Future.value();
}