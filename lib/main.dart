import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_background/animated_background.dart'; 
import 'package:remixicon/remixicon.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';  // Per FontAwesome
import 'package:provider/provider.dart';
import 'config/web_config.dart' if (dart.library.io) 'config/mobile_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'pages/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login/login_screen.dart';
import 'models/viaggio.dart';
import 'pages/viaggio_dettaglio_page.dart';
import 'pages/modifica_viaggio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/setting_page.dart';
import 'firebase_options.dart';
import 'models/travel_state.dart';
import 'pages/diario/Diary_Page.dart';
import '../widgets/skeleton_loader.dart';
import 'app_wrapper.dart';
import 'theme/app_themes.dart';
import 'package:travel_sage/services/firestore_service.dart';
import 'dart:async';
import 'package:travel_sage/services/gemini_api.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Configurazione ambiente e performance
  WidgetsFlutterBinding.ensureInitialized();
  await _setupEnvironment();
  
  // Esegui l'app con gestione degli errori
  runZonedGuarded(
    () => runApp(
      MaterialApp(
        navigatorKey: globalNavigatorKey,
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Pre-carica le risorse comuni
          _precacheCommonResources(context);
          return child!;
        },
      ),
    ),
    (error, stack) => _handleStartupError(error, stack),
  );

  // Inizializzazione servizi in background
  unawaited(_initializeAppServices());
}

Future<void> _setupEnvironment() async {
  // Configurazioni di debug
  debugPrintRebuildDirtyWidgets = false;
  debugProfileBuildsEnabled = false;
  
  // Caricamento variabili ambiente
  await dotenv.load(fileName: ".env");

  // Configurazione localizzazione
  await initializeDateFormatting('it_IT', null);
}

Future<void> _initializeAppServices() async {
  try {
    await Future.wait([
      _initializeFirebaseWithRetry(),
      _loadEssentialResources(),
    ], eagerError: true);
    
    // Log analytics solo dopo inizializzazione completata
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAnalytics.instance.logAppOpen();
    }
  } catch (e, stack) {
    _handleStartupError(e, stack);
  }
}

Future<void> _initializeFirebaseWithRetry({int maxRetries = 3}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    try {
      debugPrint("🔥 Tentativo ${attempts + 1} di inizializzazione Firebase");

      // MODIFICA QUI: Verifica più accurata se Firebase è già inizializzato
      if (Firebase.apps.isEmpty || !Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
        final options = kIsWeb 
            ? WebConfig.firebaseOptions 
            : DefaultFirebaseOptions.currentPlatform;

        final app = await Firebase.initializeApp(
          options: options,
          name: '[DEFAULT]' // Esplicitiamo il nome DEFAULT
        ).timeout(const Duration(seconds: 15));

        debugPrint("✅ Firebase inizializzato: ${app.name}");

        if (!kIsWeb) {
          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(true);
          FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
        }
        return;
      } else {
        debugPrint("ℹ️ Firebase è già inizializzato");
        return;
      }
    } on TimeoutException catch (e) {
      debugPrint("⏱ Timeout Firebase: $e");
    } catch (e, stack) {
      debugPrint("❌ Errore inizializzazione Firebase: $e\n$stack");
      if (attempts == maxRetries - 1) rethrow;
    }

    attempts++;
    await Future.delayed(const Duration(seconds: 2));
  }
}

Future<void> _loadEssentialResources() async {
  try {
    // Caricamento in parallelo di risorse essenziali
    await Future.wait([
      GoogleFonts.pendingFonts([GoogleFonts.roboto(), GoogleFonts.poppins()]),
      Future.delayed(const Duration(milliseconds: 1500)), // Minimo splash time
    ]);
  } catch (e) {
    debugPrint("⚠️ Errore caricamento risorse: $e");
    if (!kIsWeb) rethrow;
  }
}

void _precacheCommonResources(BuildContext context) {
  // Pre-caricamento di risorse comuni
  precacheImage(const AssetImage('assets/Travelsage.png'), context);
  precacheImage(const AssetImage('assets/animations/splash_travel.json'), context);
}

void _handleStartupError(dynamic error, StackTrace stack) {
  debugPrint("‼️ ERRORE CRITICO: ${error.toString()}");
  debugPrint(stack.toString());

  // Registra l'errore su Crashlytics se disponibile
  if (!kIsWeb && Firebase.apps.isNotEmpty) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  }

  // Mostra UI di errore
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 20),
                  Text(
                    kIsWeb ? 'Errore di connessione' : 'Errore nell\'avvio',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _simplifyErrorMessage(error.toString()),
                      style: GoogleFonts.roboto(
                        color: Colors.red[700],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildActionButtons(error),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildActionButtons(dynamic error) {
  return Column(
    children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: () => main(),
        child: const Text(
          'Riprova',
          style: TextStyle(color: Colors.white),
        ),
      ),
      if (!kIsWeb && error.toString().contains('Firebase')) ...[
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            runApp(
              MaterialApp(
                home: AppWrapper(enableFirebase: false),
                debugShowCheckedModeBanner: false,
              ),
            );
          },
          child: const Text('Continua senza Firebase'),
        ),
      ]
    ],
  );
}

String _simplifyErrorMessage(String error) {
  const connectionErrors = [
    'Failed to load FirebaseOptions',
    'SocketException',
    'Network is unreachable'
  ];

  if (connectionErrors.any(error.contains)) {
    return kIsWeb
        ? 'Errore di connessione al server. Verifica la tua connessione internet.'
        : 'Problema di connessione. Verifica la tua rete e riprova.';
  }

  if (error.contains('MissingPluginException')) {
    return 'Errore nei plugin nativi. Prova a ricostruire l\'app.';
  }

  return error.length > 150 ? '${error.substring(0, 150)}...' : error;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Controllori animazione
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Color?> _colorShift;

  late AnimationController _exitController;
  late Animation<double> _fadeOut;
  late Animation<double> _slideUp;

  late AnimationController _messageController;
  late Animation<double> _messageFade;

  // Messaggi di caricamento
  final List<String> _loadingMessages = [
    'Stiamo preparando la tua avventura...',
    'Caricamento destinazioni...',
    'Accendiamo la bussola...',
    'Controllo del meteo...',
    'Impostazione del budget...',
    'Verifica bagagli virtuali...',
    'Pronto a partire!',
  ];

  late Timer _messageTimer;
  int _currentMessageIndex = 0;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    // Configurazione animazioni di entrata
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeInOutCubic,
    );
    
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _colorShift = ColorTween(
      begin: const Color(0xFF3EC8F6),
      end: const Color(0xFF6D5DF6),
    ).animate(_entryController);

    // Configurazione animazioni di uscita
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideUp = Tween<double>(begin: 0.0, end: -0.1).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeIn,
      ),
    );

    // Animazione per i messaggi
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _messageFade = CurvedAnimation(
      parent: _messageController,
      curve: Curves.easeInOut,
    );

    // Avvia le animazioni di entrata
    _entryController.forward();

    // Ciclo dei messaggi di caricamento
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _messageController.reverse().then((_) {
        if (mounted && !_isTransitioning) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
          });
          _messageController.forward();
        }
      });
    });

    // Timer per la transizione alla prossima schermata
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        setState(() => _isTransitioning = true);
        await _exitController.forward();
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const TravelSageApp(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 1000),
    );

    Navigator.of(globalNavigatorKey.currentContext!).pushReplacement(route);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    _messageController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  double _calculateLogoSize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide > 600) return 250;
    if (shortestSide > 400) return 180;
    return 140;
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = _calculateLogoSize(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _exitController]),
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Sfondo animato con gradient shift
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _colorShift.value!,
                      const Color(0xFF6D5DF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              
              // Particelle animate
              AnimatedBackground(
                behaviour: RandomParticleBehaviour(
                  options: ParticleOptions(
                    baseColor: Colors.white.withOpacity(0.2),
                    spawnOpacity: 0.0,
                    opacityChangeRate: 0.25,
                    minOpacity: 0.1,
                    maxOpacity: 0.4,
                    spawnMinSpeed: 30.0,
                    spawnMaxSpeed: 70.0,
                    particleCount: 40,
                    spawnMaxRadius: 30.0,
                    spawnMinRadius: 10.0,
                  ),
                ),
                vsync: this,
                child: Container(),
              ),
              
              // Contenuto principale con animazioni
              Transform.translate(
                offset: Offset(0, _slideUp.value * screenHeight),
                child: Opacity(
                  opacity: _fadeOut.value,
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: ScaleTransition(
                        scale: _scaleIn,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            ClipOval(
                              child: Image.asset(
                                'assets/Travelsage.png',
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Barra di progresso
                            SizedBox(
                              width: logoSize * 0.4,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Animazione Lottie
                            Lottie.asset(
                              'assets/animations/splash_travel.json',
                              width: 120,
                              height: 120,
                              repeat: true,
                              frameRate: FrameRate(60),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Messaggio di caricamento con animazione
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.1),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                _loadingMessages[_currentMessageIndex],
                                key: ValueKey(_loadingMessages[_currentMessageIndex]),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

List<Viaggio> viaggiBozza = [];

class TravelSageApp extends StatelessWidget {
  const TravelSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          content = const MainNavigation();
        } else {
          content = LoginScreen(onLoginSuccess: () {});
        }

        // ✅ Unico MaterialApp, definito qui con tema
        return MaterialApp(
          title: 'TravelSage',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: content,
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      OrganizeTripPage(
        onViaggioCreato: (nuovoViaggio) {
          setState(() {
            viaggiBozza.add(nuovoViaggio);
          });
        },
      ),
      TripsPage(
        onAddNewTrip: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganizeTripPage(
                onViaggioCreato: (viaggio) {
                  setState(() {
                    viaggiBozza.add(viaggio);
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      ),
      DiaryPage(), // <-- nuova pagina aggiunta qui
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.auto_fix_high), label: 'Travelbuilder'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Mytravels'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Journal'), // nuova voce
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        type: BottomNavigationBarType.fixed, // per più di 3 elementi
      ),
    );
  }
}

class OrganizeTripPage extends StatefulWidget {
  final Function(Viaggio) onViaggioCreato;

  const OrganizeTripPage({super.key, required this.onViaggioCreato});

  @override
  State<OrganizeTripPage> createState() => _OrganizeTripPageState();
}

class _OrganizeTripPageState extends State<OrganizeTripPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String destination = '';
  String departure = '';
  DateTime? startDate;
  DateTime? endDate;
  String budget = '';
  List<String> participants = [];
  String profiloViaggiatore = '';
  bool usaIA = true;

  // Nuovi campi
  int attivitaGiornaliere = 3;
  double raggioKm = 10;
  double etaMedia = 30;
  String tipologiaViaggiatore = 'Backpacker';
  String mezzoTrasporto = 'Aereo';

  final interessiDisponibili = ['Cultura', 'Natura', 'Relax', 'Cibo', 'Sport', 'Storia', 'Arte','Nightlife'];
  List<String> interessiSelezionati = []; // Nessuno selezionato di default

  final tipiViaggiatori = ['Backpacker', 'Luxurytraveller', 'Familytraveller', 'Digitalnomad', 'Roadtripper'];
  final mezziTrasporto = [
  {'nome': 'Aereo', 'icona': RemixIcons.plane_fill},
  {'nome': 'Auto', 'icona': RemixIcons.car_fill},
  {'nome': 'Moto', 'icona': RemixIcons.motorbike_fill},
  {'nome': 'Nave', 'icona': RemixIcons.ship_fill},
  {'nome': 'Camper', 'icona': RemixIcons.bus_2_fill},
  {'nome': 'Treno', 'icona': RemixIcons.train_fill},];
  final TextEditingController _participantController = TextEditingController();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  double responsiveIconSize(double screenWidth) {
    if (screenWidth < 400) return 24;
    if (screenWidth < 600) return 28;
    return 32;
  }

  double responsiveChipFont(double screenWidth) {
    if (screenWidth < 400) return 12;
    return 14;
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  DateTime _parseActivityTime(String timeString) {
    final now = DateTime.now();
    final timeParts = timeString.split(':');
    return DateTime(
      now.year, now.month, now.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() &&
        startDate != null &&
        endDate != null &&
        participants.isNotEmpty) {
      try {
        if (usaIA) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Generazione itinerario...')),
          );

          final gemini = GeminiApi();
          final rawResponse = await gemini.generaItinerario(
            partenza: departure.trim(),
            destinazione: destination.trim(),
            dataInizio: startDate!,
            dataFine: endDate!,
            budget: budget.trim(),
            interessi: List.from(interessiSelezionati),
            mezzoTrasporto: mezzoTrasporto,
            attivitaGiornaliere: attivitaGiornaliere,
            raggioKm: raggioKm,
            etaMedia: etaMedia,
            tipologiaViaggiatore: tipologiaViaggiatore,
            profilo: profiloViaggiatore,
          );

          print('🔍 Risposta raw Gemini:\n$rawResponse');

          String estraiJson(String text) {
            final start = text.indexOf('{');
            final end = text.lastIndexOf('}');
            if (start != -1 && end != -1 && end > start) {
              return text.substring(start, end + 1);
            }
            throw FormatException('JSON non trovato nella risposta');
          }

          late final String jsonString;

          try {
            jsonString = estraiJson(rawResponse);
          } catch (e) {
            print('❌ Errore estrazione JSON: $e');
            throw Exception('Risposta Gemini non contiene JSON valido');
          }

          print('🔍 JSON estratto:\n$jsonString');

          final Map<String, dynamic> decoded = jsonDecode(jsonString);
          final Map<String, List<Attivita>> itinerario = {};

          DateTime parseOrario(String? timeString, DateTime giorno) {
            try {
              if (timeString == null || !timeString.contains(':')) {
                return DateTime(giorno.year, giorno.month, giorno.day, 0, 0);
              }
              final parts = timeString.split(':');
              return DateTime(
                giorno.year,
                giorno.month,
                giorno.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
            } catch (e) {
              print('❗️Errore parsing orario: $e, input: $timeString');
              return DateTime(giorno.year, giorno.month, giorno.day, 0, 0);
            }
          }

          final giorniTotali = endDate!.difference(startDate!).inDays + 1;
          final dateList = List.generate(
              giorniTotali, (i) => startDate!.add(Duration(days: i)));

          int index = 0;
          decoded.forEach((key, attivitaList) {
            final giorno =
                index < dateList.length ? dateList[index] : dateList.last;
            final keyGiorno = DateFormat('yyyy-MM-dd').format(giorno);

            if (attivitaList is List) {
              itinerario[keyGiorno] = attivitaList.map<Attivita>((a) {
                return Attivita(
                  id: const Uuid().v4(),
                  titolo: a['titolo'] ?? 'Attività',
                  descrizione: a['descrizione'] ?? '',
                  orario: parseOrario(a['orario'], giorno),
                  luogo: a['luogo'] ?? '',
                  completata: false,
                  categoria: a['categoria'] ?? 'attività',
                  costoStimato: (a['costoStimato'] is num)
                      ? (a['costoStimato'] as num).toDouble()
                      : 0.0,
                  generataDaIA: true,
                );
              }).toList();
            }

            index++;
          });

          final nuovoViaggio = Viaggio(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            titolo: destination.trim(),
            partenza: departure.trim(),
            destinazione: destination.trim(),
            dataInizio: startDate!,
            dataFine: endDate!,
            budget: budget.trim(),
            partecipanti: List.from(participants),
            mezzoTrasporto: mezzoTrasporto,
            attivitaGiornaliere: attivitaGiornaliere,
            raggioKm: raggioKm,
            etaMedia: etaMedia,
            tipologiaViaggiatore: tipologiaViaggiatore,
            confermato: false,
            spese: [],
            archiviato: false,
            note: null,
            itinerario: itinerario,
            interessi: List.from(interessiSelezionati),
          );

          await FirestoreService().saveViaggio(nuovoViaggio);
          widget.onViaggioCreato(nuovoViaggio);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viaggio creato con successo')),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViaggioDettaglioPage(viaggio: nuovoViaggio, index: -1),
            ),
          );
        } else {
          // 🎯 IA disattivata: viaggio vuoto
          final nuovoViaggio = Viaggio(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            titolo: destination.trim(),
            partenza: departure.trim(),
            destinazione: destination.trim(),
            dataInizio: startDate!,
            dataFine: endDate!,
            budget: budget.trim(),
            partecipanti: List.from(participants),
            mezzoTrasporto: mezzoTrasporto,
            attivitaGiornaliere: attivitaGiornaliere,
            raggioKm: raggioKm,
            etaMedia: etaMedia,
            tipologiaViaggiatore: tipologiaViaggiatore,
            confermato: false,
            spese: [],
            archiviato: false,
            note: null,
            itinerario: {},
            interessi: List.from(interessiSelezionati),
          );

          await FirestoreService().saveViaggio(nuovoViaggio);
          widget.onViaggioCreato(nuovoViaggio);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viaggio creato (manuale)')),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViaggioDettaglioPage(viaggio: nuovoViaggio, index: -1),
            ),
          );
        }
      } catch (e, stackTrace) {
        print('❌ Errore generazione viaggio: $e');
        print(stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella creazione del viaggio: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa tutti i campi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizza Viaggio'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: FaIcon(FontAwesomeIcons.rocket)),
            Tab(icon: FaIcon(FontAwesomeIcons.userAstronaut)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildViaggioTab(theme, screenWidth),
                  _buildViaggiatoreTab(theme, screenWidth),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Organizza Viaggio', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: Colors.indigo,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildViaggioTab(ThemeData theme, double screenWidth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTextField('Partenza', Icons.flight_takeoff, (val) => departure = val),
        const SizedBox(height: 16),
        _buildTextField('Destinazione', Icons.location_on_outlined, (val) => destination = val),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePicker('Data Inizio', true, startDate)),
            const SizedBox(width: 16),
            Expanded(child: _buildDatePicker('Data Fine', false, endDate)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Budget per persona (€)', Icons.euro_outlined, (val) => budget = val,
            isNumeric: true),
        const SizedBox(height: 24),
        Text('Mezzo di trasporto', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 16,
          runSpacing: 12,
          children: mezziTrasporto.map((mezzo) {
            final nome = mezzo['nome'] as String;
            final icona = mezzo['icona'] as IconData;
            final selezionato = mezzoTrasporto == nome;
            return Tooltip(
              message: nome,
              child: GestureDetector(
                onTap: () => setState(() => mezzoTrasporto = nome),
                child: CircleAvatar(
                  radius: screenWidth < 400 ? 22 : 28,
                  backgroundColor: selezionato ? Colors.indigo : Colors.grey[300],
                  child: Icon(
                    icona,
                    size: screenWidth < 400 ? 20 : 28,
                    color: selezionato ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildSlider('Attività giornaliere', attivitaGiornaliere.toDouble(), 1, 8,
            (val) => setState(() => attivitaGiornaliere = val.round())),
        const SizedBox(height: 8),
        _buildSlider('Raggio massimo (km)', raggioKm, 0, 500,
            (val) => setState(() => raggioKm = val), step: 15),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sfrutta l'assistente IA per generare l'itinerario",
                style: theme.textTheme.bodyLarge,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 4),
              const Icon(Icons.smart_toy_sharp, color: Colors.indigo),
            ],
          ),
          value: usaIA,
          onChanged: (val) => setState(() => usaIA = val),
        ),
      ],
    );
  }

  Widget _buildViaggiatoreTab(ThemeData theme, double screenWidth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSlider('Età media', etaMedia, 10, 100, (val) => setState(() => etaMedia = val)),
        const SizedBox(height: 32),
        Text('Tipologia Viaggiatore', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildViaggiatoreIcon(Icons.backpack, 'Backpacker', screenWidth),
            _buildViaggiatoreIcon(RemixIcons.diamond_fill, 'Luxury', screenWidth),
            _buildViaggiatoreIcon(Icons.family_restroom, 'Family', screenWidth),
            _buildViaggiatoreIcon(RemixIcons.computer_fill, 'Digital Nomad', screenWidth),
            _buildViaggiatoreIcon(RemixIcons.car_fill, 'Road Tripper', screenWidth),
          ],
        ),
        const SizedBox(height: 32),
        Text('Interessi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: interessiDisponibili.map((interesse) => FilterChip(
            label: Text(
              interesse,
              style: TextStyle(fontSize: responsiveChipFont(screenWidth)),
            ),
            selected: interessiSelezionati.contains(interesse),
            onSelected: (selected) => setState(() {
              if (selected) {
                interessiSelezionati.add(interesse);
              } else {
                interessiSelezionati.remove(interesse);
              }
            }),
          )).toList(),
        ),
        const SizedBox(height: 32),
        Text('Partecipanti', style: theme.textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: participants.map((p) => Chip(
            label: Text(p),
            onDeleted: () => setState(() => participants.remove(p)),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _participantController,
                decoration: const InputDecoration(labelText: 'Aggiungi partecipante'),
                onSubmitted: (val) => _addParticipant(val),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addParticipant(_participantController.text),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String) onChanged,
      {bool isNumeric = false}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      keyboardType: isNumeric ? TextInputType.number : null,
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
    );
  }

  Widget _buildDatePicker(String label, bool isStart, DateTime? selectedDate) {
    return InkWell(
      onTap: () => _selectDate(isStart),
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(selectedDate == null
            ? 'Seleziona'
            : DateFormat('dd/MM/yyyy').format(selectedDate)),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      Function(double) onChanged,
      {int? step}) {
    final divisions = step != null ? ((max - min) / step).round() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildViaggiatoreIcon(IconData icon, String tipo, double screenWidth) {
    final bool selected = tipologiaViaggiatore == tipo;
    return Tooltip(
      message: tipo,
      child: GestureDetector(
        onTap: () => setState(() => tipologiaViaggiatore = tipo),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Colors.indigo : Colors.grey[300],
            boxShadow: selected
                ? [BoxShadow(color: Colors.indigo.withOpacity(0.5), blurRadius: 8)]
                : [],
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: selected ? Colors.white : Colors.black54,
            size: responsiveIconSize(screenWidth),
          ),
        ),
      ),
    );
  }

  void _addParticipant(String name) {
    if (name.trim().isNotEmpty) {
      setState(() {
        participants.add(name.trim());
        _participantController.clear();
      });
    }
  }
}


class TripsPage extends StatefulWidget {
  final VoidCallback onAddNewTrip;

  const TripsPage({super.key, required this.onAddNewTrip});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  List<Viaggio> viaggiBozza = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await _caricaViaggi();
      _archiviaViaggiScaduti();
    });
  }

  Future<void> _caricaViaggi() async {
    try {
      final viaggi = await FirestoreService().getViaggi();
      setState(() {
        viaggiBozza = viaggi;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore caricamento viaggi: $e')),
      );
    }
  }

  double calcolaTotaleStimato(Map<String, List<Attivita>> itinerario) {
  double totale = 0.0;
    for (var attList in itinerario.values) {
      for (var att in attList) {
        totale += att.costoStimato ?? 0.0;
      }
    }
    return totale;
  }

  void _archiviaViaggiScaduti() {
    final oggi = DateTime.now();
    final viaggiArchiviati = <String>[];

    bool aggiorna = false;

    for (int i = 0; i < viaggiBozza.length; i++) {
      final viaggio = viaggiBozza[i];
      final dataFine = viaggio.dataFine;

      final nonArchiviato = !viaggio.archiviato;
      final confermato = viaggio.confermato;
      final scaduto = dataFine.isBefore(oggi);

      if (confermato && nonArchiviato && scaduto) {
        viaggiBozza[i] = viaggio.copyWith(archiviato: true);
        TravelState.viaggiDaArchiviare.add({'destinazione': viaggio.destinazione}); // Cambiato per più leggibilità
        aggiorna = true;
      }
    }

    if (aggiorna) {
      setState(() {});  // Aggiorna UI se cambiamenti
    }

    if (TravelState.viaggiDaArchiviare.isNotEmpty) {
      final snackText = '${TravelState.viaggiDaArchiviare.length} viaggi archiviati automaticamente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackText),
          backgroundColor: Colors.indigo,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'DETTAGLI',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Viaggi Archiviati'),
                  content: Text(TravelState.viaggiDaArchiviare.join('\n')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina viaggio'),
        content: const Text('Sei sicuro di voler eliminare questo viaggio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              await FirestoreService().deleteViaggio(viaggiBozza[index].id);
              setState(() {
                viaggiBozza.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viaggiNonArchiviati = viaggiBozza.where((v) => !v.archiviato).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Viaggi salvati'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (viaggiNonArchiviati.isEmpty
              ? const SkeletonLoader()
              : _buildViaggiGrid(context, viaggiNonArchiviati)),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddNewTrip,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
        tooltip: 'Aggiungi nuovo viaggio',
      ),
    );
  }

  Widget _buildViaggiGrid(BuildContext context, List<Viaggio> viaggiNonArchiviati) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    
    int cardsPerRow;
    double cardHeight;

    if (screenWidth >= 1200) {
      cardsPerRow = 4;
      cardHeight = 220;
    } else if (screenWidth >= 800) {
      cardsPerRow = 3;
      cardHeight = 200;
    } else if (screenWidth >= 600) {
      cardsPerRow = 2;
      cardHeight = 180;
    } else {
      cardsPerRow = 1;
      cardHeight = 160;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.builder(
        itemCount: viaggiNonArchiviati.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cardsPerRow,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: (screenWidth / cardsPerRow) / cardHeight,
        ),
        itemBuilder: (context, index) {
          final viaggio = viaggiNonArchiviati[index];
          final originalIndex = viaggiBozza.indexOf(viaggio);
          final imageUrl = 'https://source.unsplash.com/400x200/?travel,${viaggio.destinazione}';
          final titoloDaMostrare = viaggio.titolo.isNotEmpty
              ? viaggio.titolo
              : 'Viaggio a ${viaggio.destinazione}';
          final totale = calcolaTotaleStimato(viaggio.itinerario);
          final haSuperatoBudget = totale > (double.tryParse(viaggio.budget) ?? double.infinity);
          final colorePreventivo = haSuperatoBudget ? Colors.redAccent : theme.colorScheme.secondary;

          return InkWell(
            key: Key('${viaggio.destinazione}_${viaggio.dataInizio.millisecondsSinceEpoch}'),
            onTap: () {
              if (viaggio.confermato) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViaggioDettaglioPage(
                      viaggio: viaggio,
                      index: originalIndex,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModificaViaggioPage(
                      viaggio: viaggio,
                      index: originalIndex,
                    ),
                  ),
                ).then((_) => setState(() {}));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          viaggio.confermato ? Icons.check_circle : Icons.edit_note,
                          color: viaggio.confermato ? Colors.greenAccent : Colors.orangeAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            titoloDaMostrare,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!viaggio.confermato)
                          ElevatedButton(
                            onPressed: () async {
                              final confermatoViaggio = viaggio.copyWith(confermato: true);
                              await FirestoreService().saveViaggio(confermatoViaggio);
                              setState(() {
                                viaggiBozza[originalIndex] = confermatoViaggio;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Conferma'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteDialog(context, originalIndex),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(viaggio.dataInizio)} → ${DateFormat('dd/MM/yyyy').format(viaggio.dataFine)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    Tooltip(
                      message: haSuperatoBudget
                          ? "Hai sforato il budget previsto"
                          : "Spesa stimata entro il budget",
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.euro, size: 18, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            "Preventivo: €${totale.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorePreventivo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          viaggio.confermato ? Icons.lock_open_rounded : Icons.edit,
                          size: 16,
                          color: viaggio.confermato ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          viaggio.confermato ? 'Viaggio confermato' : 'Bozza in lavorazione',
                          style: TextStyle(
                            fontSize: 13,
                            color: viaggio.confermato ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
