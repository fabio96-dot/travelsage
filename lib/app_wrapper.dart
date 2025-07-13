import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'pages/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Caricamento eventuali risorse aggiuntive
      await Future.wait([
        // Aggiungi qui altri servizi da inizializzare
        Future.delayed(const Duration(milliseconds: 500)), // Delay minimo per lo splash
      ]);
    } catch (e) {
      debugPrint("AppWrapper initialization error: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // Mostra lo splash screen durante il caricamento
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        // Gestione errori
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error!);
        }

        // Contenuto principale
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

  Widget _buildErrorScreen(dynamic error) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              Text(
                'Errore di inizializzazione',
                style: GoogleFonts.roboto(fontSize: 20),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AppWrapper()),
                ),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}