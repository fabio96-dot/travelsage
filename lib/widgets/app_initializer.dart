import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:travel_sage/firebase_options.dart';
import 'package:travel_sage/main.dart'; // Assicurati che il percorso sia corretto

class AppInitializer extends StatelessWidget {
  final Widget child;
  
  const AppInitializer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Errore di inizializzazione', style: TextStyle(fontSize: 24)),
                    Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: () => _retryInitialization(context),
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        return snapshot.hasData ? child : const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<bool> _initializeApp() async {
    try {
      await dotenv.load(fileName: '.env');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (e) {
      debugPrint('Initialization error: $e');
      rethrow;
    }
  }

  void _retryInitialization(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TravelSageApp()),
    );
  }
}