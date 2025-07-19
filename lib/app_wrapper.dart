import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/web_config.dart' if (dart.library.io) 'config/mobile_config.dart';
import 'pages/theme_provider.dart';
import 'firebase_options.dart';
import 'main.dart'; // per SplashScreen e TravelSageApp

class AppWrapper extends StatefulWidget {
  final bool enableFirebase;
  
  const AppWrapper({
    Key? key,
    this.enableFirebase = true,
  }) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  late Future<void> _initialization;
  bool _initializationError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Caricamento configurazioni base
      await _loadEssentialConfigurations();

      // 2. Inizializzazione Firebase (se abilitato)
      if (widget.enableFirebase) {
        await _initializeFirebaseServices();
      }

      // 3. Caricamento risorse aggiuntive
      await _loadAdditionalResources();

    } catch (e, stack) {
      _handleInitializationError(e, stack);
    }
  }

  Future<void> _loadEssentialConfigurations() async {
    await Future.wait([
      WebConfig.waitForConfig(),
      initializeDateFormatting('it_IT', null),
    ]);
  }

Future<void> _initializeFirebaseServices() async {
  try {
    // MODIFICA QUI: Verifica più robusta dell'inizializzazione
    if (widget.enableFirebase && 
        (Firebase.apps.isEmpty || !Firebase.apps.any((app) => app.name == '[DEFAULT]'))) {
      
      debugPrint("⚙️ Tentativo di inizializzazione Firebase da AppWrapper");
      
      await Firebase.initializeApp(
        options: kIsWeb 
            ? WebConfig.firebaseOptions 
            : DefaultFirebaseOptions.currentPlatform,
        name: 'Secondary' // Usa un nome diverso per questa inizializzazione
      );

      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      }
    } else {
      debugPrint("ℹ️ Firebase già inizializzato, salto l'inizializzazione");
    }
  } catch (e, stack) {
    debugPrint("⚠️ Errore nell'inizializzazione secondaria di Firebase: $e");
    // Non blocchiamo l'app per questo errore
  }
}

  Future<void> _loadAdditionalResources() async {
    await Future.wait([
      GoogleFonts.pendingFonts([GoogleFonts.poppins(), GoogleFonts.roboto()]),
      Future.delayed(const Duration(milliseconds: 800)), // Tempo minimo per splash screen
    ]);
  }

  void _handleInitializationError(dynamic e, StackTrace stack) {
    debugPrint('⚠️ AppWrapper initialization error: $e');
    debugPrint(stack.toString());

    setState(() {
      _initializationError = true;
      _errorMessage = e.toString();
    });

    if (!kIsWeb && widget.enableFirebase && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            navigatorObservers: [
              if (widget.enableFirebase && Firebase.apps.isNotEmpty)
                FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
            home: _buildAppContent(),
          );
        },
      ),
    );
  }

  Widget _buildAppContent() {
    if (_initializationError) {
      return _buildErrorScreen();
    }

    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        return const TravelSageApp();
      },
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text(
                'Errore di inizializzazione',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _errorMessage ?? 'Errore sconosciuto',
                style: GoogleFonts.roboto(
                  color: Colors.red[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.of(globalNavigatorKey.currentContext!)
                    .pushReplacement(MaterialPageRoute(
                  builder: (_) => const AppWrapper(),
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Riprova',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (!widget.enableFirebase) ...[
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.of(globalNavigatorKey.currentContext!)
                      .pushReplacement(MaterialPageRoute(
                    builder: (_) => const AppWrapper(enableFirebase: false),
                  )),
                  child: const Text('Continua in modalità offline'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}