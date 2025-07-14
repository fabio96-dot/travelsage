import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart'; // aggiorna percorso se serve
import 'config/web_config.dart' if (dart.library.io) 'config/mobile_config.dart';
import 'pages/theme_provider.dart';
import 'main.dart'; // per SplashScreen e TravelSageApp

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  late Future<void> _initialization;

  int _firebaseInitAttempts = 0;
  static const int maxFirebaseInitAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Inizializza date formatting
    await initializeDateFormatting('it_IT', null);

    // Aspetta config web se necessario
    await WebConfig.waitForConfig();

    // Prova a inizializzare Firebase con retry
    while (_firebaseInitAttempts < maxFirebaseInitAttempts) {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: kIsWeb ? WebConfig.firebaseOptions : DefaultFirebaseOptions.currentPlatform,
          );
        }

        if (!kIsWeb) {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
          FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
        }

        // Se arriviamo qui, Firebase inizializzato correttamente
        return;
      } catch (e) {
        _firebaseInitAttempts++;
        debugPrint("Firebase init attempt $_firebaseInitAttempts failed: $e");
        if (_firebaseInitAttempts >= maxFirebaseInitAttempts) {
          rethrow; // Fallisce definitivamente
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _retryInitialization() {
    setState(() {
      _firebaseInitAttempts = 0;
      _initialization = _initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        // Durante il caricamento mostra splash
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        // Se errore mostra schermata con retry
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error);
        }

        // Se ok mostra app con provider, tema, analytics...
        return ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                navigatorObservers: [
                  FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
                ],
                home: const TravelSageApp(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen(Object? error) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 20),
                Text(
                  'Errore durante l\'inizializzazione',
                  style: GoogleFonts.roboto(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: Colors.red),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _retryInitialization,
                  child: const Text('Riprova'),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    onPressed: () {
                      // Continua senza Firebase: mostra app senza Firebase
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const TravelSageApp()),
                      );
                    },
                    child: const Text('Continua senza Firebase'),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
