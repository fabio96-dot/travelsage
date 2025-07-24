import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';  // Per FontAwesome
import 'config/web_config.dart' if (dart.library.io) 'config/mobile_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login/login_screen.dart';
import 'models/viaggio.dart';
import 'pages/viaggio_dettaglio_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/setting_page.dart';
import 'firebase_options.dart';
import 'pages/diario/Diary_Page.dart';
import '../widgets/skeleton_loader.dart';
import 'app_wrapper.dart';
import 'theme/app_themes.dart';
import 'package:travel_sage/services/firestore_service.dart';
import 'dart:async';
import 'package:travel_sage/services/gemini_api.dart';
import 'dart:convert';
import 'pages/viaggiocreatoAI.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/viaggio_form_tab.dart';
import 'providers/organize_trip_controller.dart';
import 'pages/viaggiatore_form_tab.dart';
import 'providers/theme_provider.dart';
import 'providers/travel_provider.dart';
import 'providers/splash_screen_provider.dart';
import 'services/unsplash_api.dart';



final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {

  await runZonedGuarded(() async {
    // Inizializzazione dentro la stessa zona
    WidgetsFlutterBinding.ensureInitialized();

    await _setupEnvironment();
    await _initializeAppServices();

    runApp(
      const ProviderScope(
        child: AppEntryPoint(),
      ),
    );
  }, (error, stack) => _handleStartupError(error, stack));
}

class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(), // Mostra splash screen all'avvio
    );
  }
}

Future<void> _setupEnvironment() async {
  debugPrintRebuildDirtyWidgets = false;
  debugProfileBuildsEnabled = false;

  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('it_IT', null);
}

Future<void> _initializeAppServices() async {
  try {
    await Future.wait([
      _initializeFirebaseWithRetry(),
      _loadEssentialResources(),
    ], eagerError: true);

    if (Firebase.apps.isNotEmpty) {
      unawaited(FirebaseAnalytics.instance.logAppOpen());
    }
  } catch (e, stack) {
    _handleStartupError(e, stack);
    rethrow; // Importante per far propagare l'errore a runZonedGuarded
  }
}

Future<void> _initializeFirebaseWithRetry({int maxRetries = 3}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    try {
      debugPrint("🔥 Tentativo ${attempts + 1} di inizializzazione Firebase");

      if (Firebase.apps.isEmpty || !Firebase.apps.any((app) => app.name == '[DEFAULT]')) {
        final options = kIsWeb
            ? WebConfig.firebaseOptions
            : DefaultFirebaseOptions.currentPlatform;

        final app = await Firebase.initializeApp(
          options: options,
          name: '[DEFAULT]',
        ).timeout(const Duration(seconds: 15));

        debugPrint("✅ Firebase inizializzato: ${app.name}");

        if (!kIsWeb) {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
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
    await Future.wait([
      GoogleFonts.pendingFonts([GoogleFonts.roboto(), GoogleFonts.poppins()]),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
  } catch (e) {
    debugPrint("⚠️ Errore caricamento risorse: $e");
    if (!kIsWeb) rethrow;
  }
}

void _handleStartupError(dynamic error, StackTrace stack) {
  debugPrint("‼️ ERRORE CRITICO: ${error.toString()}");
  debugPrint(stack.toString());

  if (!kIsWeb && Firebase.apps.isNotEmpty) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  }

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
                home: const AppWrapper(enableFirebase: false),
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

List<Viaggio> viaggiBozza = [];

class TravelSageApp extends StatelessWidget {
  const TravelSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return const MainNavigation();
        } else {
          return LoginScreen(onLoginSuccess: () {});
        }
      },
    );
  }
}

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final pages = [
      OrganizeTripPage(
        onViaggioCreato: (nuovoViaggio) {
          // Aggiorna lo stato se serve
        },
      ),
      TripsPage(
        onAddNewTrip: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrganizeTripPage(
                onViaggioCreato: (viaggio) {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      ),
      DiaryPage(),
      const SettingsPage(),
    ];

    void onItemTapped(int index) {
      ref.read(selectedIndexProvider.notifier).state = index;
    }

    return Scaffold(
      // Usa IndexedStack per mantenere le pagine montate
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.auto_fix_high), label: 'Travelbuilder'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Mytravels'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Journal'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}



class OrganizeTripPage extends ConsumerStatefulWidget {
  final Function(Viaggio) onViaggioCreato;

  const OrganizeTripPage({Key? key, required this.onViaggioCreato}) : super(key: key);

  @override
  ConsumerState<OrganizeTripPage> createState() => _OrganizeTripPageState();
}

class _GenerazioneDialog extends StatelessWidget {
  const _GenerazioneDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/travel_ai.json',
              width: 150,
              repeat: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sto creando il tuo viaggio su misura...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'Grazie alla potenza dell’intelligenza artificiale!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _OrganizeTripPageState extends ConsumerState<OrganizeTripPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _participantController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Inizializza i controller con testo vuoto o eventualmente con dati preesistenti
    _departureController.text = '';
    _destinationController.text = '';
    _budgetController.text = '';
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    _participantController.dispose();
    _tabController.dispose();
    super.dispose();
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
  final departure = _departureController.text.trim();
  final destination = _destinationController.text.trim();
  final budget = _budgetController.text.trim();
  final startDate = ref.read(startDateProvider);
  final endDate = ref.read(endDateProvider);
  final usaIA = ref.read(usaIAProvider);
  final etaMedia = ref.read(etaMediaProvider);
  final tipologiaViaggiatore = ref.read(tipologiaViaggiatoreProvider);
  final mezzoTrasporto = ref.read(mezzoTrasportoProvider);
  final attivitaGiornaliere = ref.read(attivitaGiornaliereProvider);
  final raggioKm = ref.read(raggioKmProvider);
  final interessiSelezionati = ref.read(interessiProvider);
  final participants = ref.read(partecipantiProvider);

  if (_formKey.currentState!.validate() && startDate != null && endDate != null && participants.isNotEmpty) {
    try {
      if (usaIA) {
        late BuildContext dialogContext;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            dialogContext = ctx;
            return const _GenerazioneDialog();
          },
        );

        final gemini = GeminiApi();
        final rawResponse = await gemini.generaItinerario(
          partenza: departure,
          destinazione: destination,
          dataInizio: startDate,
          dataFine: endDate,
          budget: budget,
          interessi: List.from(interessiSelezionati),
          mezzoTrasporto: mezzoTrasporto,
          attivitaGiornaliere: attivitaGiornaliere,
          raggioKm: raggioKm,
          etaMedia: etaMedia,
          tipologiaViaggiatore: tipologiaViaggiatore,
          profilo: '',
        );

        String estraiJson(String text) {
          final start = text.indexOf('{');
          final end = text.lastIndexOf('}');
          if (start != -1 && end != -1 && end > start) {
            return text.substring(start, end + 1);
          }
          throw FormatException('JSON non trovato nella risposta');
        }

        final String jsonString = estraiJson(rawResponse);
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final Map<String, List<Attivita>> itinerario = {};

        DateTime parseOrario(String? timeString, DateTime giorno) {
          try {
            if (timeString == null || !timeString.contains(':')) {
              return DateTime(giorno.year, giorno.month, giorno.day, 0, 0);
            }
            final parts = timeString.split(':');
            return DateTime(giorno.year, giorno.month, giorno.day, int.parse(parts[0]), int.parse(parts[1]));
          } catch (_) {
            return DateTime(giorno.year, giorno.month, giorno.day, 0, 0);
          }
        }

        final giorniTotali = endDate.difference(startDate).inDays + 1;
        final dateList = List.generate(giorniTotali, (i) => startDate.add(Duration(days: i)));

        int index = 0;
        decoded.forEach((key, attivitaList) {
          final giorno = index < dateList.length ? dateList[index] : dateList.last;
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
                costoStimato: (a['costoStimato'] is num) ? (a['costoStimato'] as num).toDouble() : 0.0,
                generataDaIA: true,
              );
            }).toList();
          }
          index++;
        });

        final destinazioneFinale = destination.isNotEmpty ? destination : 'Viaggio';

        final nuovoViaggio = Viaggio(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titolo: destination,
          partenza: departure,
          destinazione: destinazioneFinale,
          dataInizio: startDate,
          dataFine: endDate,
          budget: budget,
          partecipanti: List.from(participants),
          mezzoTrasporto: mezzoTrasporto,
          attivitaGiornaliere: attivitaGiornaliere,
          raggioKm: raggioKm,
          etaMedia: etaMedia,
          tipologiaViaggiatore: tipologiaViaggiatore,
          confermato: true,
          spese: [],
          archiviato: false,
          note: null,
          itinerario: itinerario,
          interessi: List.from(interessiSelezionati),
        );

        // Salvataggio delle attività nella sottocollezione 'attivita'
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final viaggioId = nuovoViaggio.id;
        final firestore = FirebaseFirestore.instance;

        for (final entry in itinerario.entries) {
          final giorno = entry.key;
          final List<Attivita> attivitaList = entry.value;

          for (final attivita in attivitaList) {
            await firestore
                .collection('users')
                .doc(userId)
                .collection('viaggi')
                .doc(viaggioId)
                .collection('attivita')
                .doc(attivita.id)
                .set({
              'id': attivita.id,
              'titolo': attivita.titolo,
              'descrizione': attivita.descrizione,
              'orario': Timestamp.fromDate(attivita.orario),
              'luogo': attivita.luogo,
              'completata': attivita.completata,
              'categoria': attivita.categoria,
              'costoStimato': attivita.costoStimato,
              'generataDaIA': attivita.generataDaIA,
              'giorno': giorno,
            });
          }
        }

        await FirestoreService().saveViaggio(nuovoViaggio);
        widget.onViaggioCreato(nuovoViaggio);

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        Navigator.of(dialogContext).pop();

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViaggioCreatoPage(viaggio: nuovoViaggio)),
        );
      } else {
        // IA disabilitata - crea viaggio senza attività
        final nuovoViaggio = Viaggio(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titolo: destination,
          partenza: departure,
          destinazione: destination,
          dataInizio: startDate,
          dataFine: endDate,
          budget: budget,
          partecipanti: List.from(participants),
          mezzoTrasporto: mezzoTrasporto,
          attivitaGiornaliere: attivitaGiornaliere,
          raggioKm: raggioKm,
          etaMedia: etaMedia,
          tipologiaViaggiatore: tipologiaViaggiatore,
          confermato: true,
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

        if (!mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViaggioDettaglioPage(
              viaggio: nuovoViaggio,
              index: 0,
            ),
          ),
        );

        if (result == true && mounted) {
          Future.microtask(() => ref.read(travelProvider.notifier).caricaViaggi());
        }
      }
    } catch (e, stackTrace) {
      print('❌ Errore generazione viaggio: $e');
      print(stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella creazione del viaggio: $e')),
      );
    }
  } else {
    if (!mounted) return;
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
    return ViaggioFormTab(
      departureController: _departureController,
      destinationController: _destinationController,
      budgetController: _budgetController,
    );
  }

  Widget _buildViaggiatoreTab(ThemeData theme, double screenWidth) {
    return ViaggiatoreFormTab(
      participantController: _participantController,
      screenWidth: screenWidth,
    );
  }
}

class TripsPage extends ConsumerStatefulWidget {
  final VoidCallback onAddNewTrip;

  const TripsPage({super.key, required this.onAddNewTrip});

  @override
  ConsumerState<TripsPage> createState() => _TripsPageState();
}

  class _TripsPageState extends ConsumerState<TripsPage> with WidgetsBindingObserver {
    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(travelProvider.notifier).archiviaViaggiScaduti();
      });
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.resumed) {
        // Quando l’app torna in primo piano, ricontrolla gli archivi
        ref.read(travelProvider.notifier).archiviaViaggiScaduti();
      }
    }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showDeleteDialog(Viaggio viaggio) {
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
              Navigator.pop(context);
              try {
                await Future.microtask(() => ref.read(travelProvider.notifier).rimuoviViaggio(viaggio.id));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
                  );
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final travelState = ref.watch(travelProvider);
    final viaggiNonArchiviati = travelState.viaggi.where((v) => !v.archiviato).toList()
      ..sort((a, b) => a.dataInizio.compareTo(b.dataInizio));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Viaggi salvati'),
      ),
      body: travelState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viaggiNonArchiviati.isEmpty
              ? const SkeletonLoader()
              : _buildViaggiGrid(context, viaggiNonArchiviati),
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
      cardHeight = 280;
    } else if (screenWidth >= 800) {
      cardsPerRow = 3;
      cardHeight = 260;
    } else if (screenWidth >= 600) {
      cardsPerRow = 2;
      cardHeight = 250;
    } else {
      cardsPerRow = 1;
      cardHeight = 240;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(travelProvider.notifier).archiviaViaggiScaduti();
      },
      child: Padding(
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
            final titolo = viaggio.titolo.trim().isNotEmpty
                ? viaggio.titolo.trim()
                : viaggio.destinazione.trim().isNotEmpty
                    ? viaggio.destinazione.trim()
                    : 'Senza Titolo';
            final totale = calcolaTotaleStimato(viaggio.itinerario);
            final haSuperatoBudget = totale > (double.tryParse(viaggio.budget) ?? double.infinity);
            final colorePreventivo = haSuperatoBudget ? Colors.redAccent : theme.colorScheme.secondary;

            return FutureBuilder<String?>(
              future: ref.read(unsplashApiProvider).getImageForViaggio(viaggio),
              builder: (context, snapshot) {
                final imageUrl = snapshot.data;

                return InkWell(
                  key: Key('${viaggio.destinazione}_${viaggio.dataInizio.millisecondsSinceEpoch}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViaggioDettaglioPage(viaggio: viaggio, index: index),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                            child: Image.network(
                              imageUrl,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.photo_outlined, color: Colors.white70, size: 40),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Colors.indigo, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      titolo,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _showDeleteDialog(viaggio),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(viaggio.dataInizio)} → ${DateFormat('dd/MM/yyyy').format(viaggio.dataFine)}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.euro, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Preventivo: €${totale.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: colorePreventivo,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
