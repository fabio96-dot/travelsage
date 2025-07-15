import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'pages/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login/login_screen.dart';
import 'models/viaggio.dart';
import 'pages/viaggio_dettaglio_page.dart';
import 'pages/modifica_viaggio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/setting_page.dart';
import 'models/travel_state.dart';
import 'pages/diario/Diary_Page.dart';
import '../widgets/skeleton_loader.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'config/web_config.dart' if (dart.library.io) 'config/mobile_config.dart';
import 'app_wrapper.dart';
import 'theme/app_themes.dart';
import 'package:travel_sage/services/firestore_service.dart';
import 'package:pedantic/pedantic.dart';
import 'dart:async';
import 'package:travel_sage/services/gemini_api.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mostra subito la splash screen
  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));

  try {
    // Caricamento parallelo delle risorse
    await Future.wait([
      _loadConfigurations(),
      _initializeEssentialServices(),
    ], eagerError: true);

    // Attesa minima per la splash screen (1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _runMainApp();
  } catch (e, stack) {
    _handleStartupError(e, stack);
  }
}

Future<void> _loadConfigurations() async {
  try {
    // Carica .env solo per mobile
    if (!kIsWeb) await dotenv.load(fileName: ".env");
    await initializeDateFormatting('it_IT', null);
  } catch (e) {
    debugPrint('Config error: $e');
    if (!kIsWeb) rethrow;
  }
}

Future<void> _initializeEssentialServices() async {
  try {
    await _initializeFirebaseWithRetry();
    unawaited(_loadGoogleFonts()); // Carica i font in background
  } catch (e) {
    debugPrint('Services init error: $e');
    rethrow;
  }
}

Future<void> _initializeFirebaseWithRetry({int maxRetries = 3}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    try {
      debugPrint("🔥 Tentativo ${attempts + 1} di inizializzazione Firebase");

      if (Firebase.apps.isEmpty) {
        final options = kIsWeb 
            ? WebConfig.firebaseOptions 
            : DefaultFirebaseOptions.currentPlatform;

        final app = await Firebase.initializeApp(options: options)
            .timeout(const Duration(seconds: 15));

        debugPrint("✅ Firebase inizializzato: ${app.name}");

        if (!kIsWeb) {
          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(true);
          FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
        }
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

Future<void> _loadGoogleFonts() async {
  try {
    await GoogleFonts.pendingFonts([GoogleFonts.roboto()]);
  } catch (e) {
    debugPrint("⚠️ Errore caricamento font: $e");
  }
}

void _runMainApp() {
  runApp(const AppWrapper());

  if (Firebase.apps.isNotEmpty) {
    FirebaseAnalytics.instance.logAppOpen();
  }
}

void _handleStartupError(dynamic e, StackTrace stack) {
  debugPrint("‼️ ERRORE CRITICO: $e\n$stack");

  if (!kIsWeb && Firebase.apps.isNotEmpty) {
    FirebaseCrashlytics.instance.recordError(e, stack);
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
                    style: GoogleFonts.roboto(fontSize: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _simplifyErrorMessage(e.toString()),
                      style: GoogleFonts.roboto(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Riprova'),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                      ),
                      onPressed: () => _runMainApp(),
                      child: const Text('Continua senza Firebase'),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _simplifyErrorMessage(String error) {
  if (error.contains('Failed to load FirebaseOptions')) {
    return kIsWeb 
        ? 'Errore di connessione al server. Verifica la tua rete.'
        : 'Configurazione Firebase mancante.';
  }
  return error;
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_travelsage.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 30),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Caricamento...',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Viaggio> viaggiBozza = [];

class TravelSageApp extends StatelessWidget {
  const TravelSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TravelSage',
      theme: AppThemes.lightTheme,              // 👈 nuovo tema chiaro
      darkTheme: AppThemes.darkTheme,           // 👈 nuovo tema scuro
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: StreamBuilder<User?>(
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
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.auto_fix_high), label: 'Organizza'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Viaggi'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Diario'), // nuova voce
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Impostazioni'),
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

class _OrganizeTripPageState extends State<OrganizeTripPage> {
  final _formKey = GlobalKey<FormState>();
  String destination = '';
  DateTime? startDate;
  DateTime? endDate;
  String budget = '';
  List<String> participants = [];
  List<String> interessiDisponibili = [
    'Cultura', 'Natura', 'Relax', 'Cibo', 'Sport', 'Storia', 'Arte',
  ];
  List<String> interessiSelezionati = [];
  final TextEditingController _participantController = TextEditingController();

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
    final nuovoViaggio = Viaggio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titolo: destination.trim(),
      destinazione: destination.trim(),
      dataInizio: startDate!,
      dataFine: endDate!,
      budget: budget.trim(),
      partecipanti: List.from(participants),
      confermato: false,
      spese: [],
      archiviato: false,
      note: null,
      itinerario: {},
      interessi: List.from(interessiSelezionati),
    );

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generazione itinerario...')),
      );

      final gemini = GeminiApi('AIzaSyBEZtNzgh97bF5uk1YOS1uKvXNzEQoogcs');
      final models = await gemini.listAvailableModels();
      print('Modelli disponibili: $models');
      
      // Sposta tutta la logica dell'itinerario in un unico blocco try
      final itinerarioJson = await gemini.generaItinerario(
        destinazione: nuovoViaggio.destinazione, // Usa i valori dal form
        dataInizio: nuovoViaggio.dataInizio,
        dataFine: nuovoViaggio.dataFine,
        budget: nuovoViaggio.budget,
        interessi: nuovoViaggio.interessi,
      );

      print('🔍 Risposta Gemini JSON:\n$itinerarioJson');

      final Map<String, dynamic> decoded = jsonDecode(itinerarioJson);
      final Map<String, List<Attivita>> itinerario = {};

      decoded.forEach((giorno, attivitaList) {
        if (attivitaList is List) {
          itinerario[giorno] = attivitaList.map<Attivita>((a) {
            return Attivita(
              id: const Uuid().v4(),
              titolo: a['titolo'] ?? 'Attività',
              descrizione: a['descrizione'] ?? '',
              orario: _parseActivityTime(a['orario']),
              luogo: a['luogo'],
            );
          }).toList();
        }
      });

      nuovoViaggio.itinerario = itinerario;

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
    } catch (e, stackTrace) {
      print('❌ Errore generazione viaggio: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella generazione del viaggio: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Organizza Viaggio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Destinazione',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onChanged: (val) => destination = val,
                validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Inizio',
                          prefixIcon: const Icon(Icons.date_range_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(startDate == null
                            ? 'Seleziona'
                            : DateFormat('dd/MM/yyyy').format(startDate!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Fine',
                          prefixIcon: const Icon(Icons.date_range_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(endDate == null
                            ? 'Seleziona'
                            : DateFormat('dd/MM/yyyy').format(endDate!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Budget per persona (€)',
                  prefixIcon: const Icon(Icons.euro_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) => budget = val,
                validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 32),
              Text('Partecipanti', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: participants
                    .map((p) => Chip(
                          label: Text(p),
                          onDeleted: () {
                            setState(() {
                              participants.remove(p);
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _participantController,
                      decoration: InputDecoration(
                        labelText: 'Aggiungi partecipante',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            participants.add(val.trim());
                            _participantController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_participantController.text.trim().isNotEmpty) {
                        setState(() {
                          participants.add(_participantController.text.trim());
                          _participantController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Icon(Icons.add),
                  )
                ],
              ),
              const SizedBox(height: 32),
              Text('Interessi del viaggio', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: interessiDisponibili.map((interesse) {
                  final selezionato = interessiSelezionati.contains(interesse);
                  return FilterChip(
                    label: Text(interesse),
                    selected: selezionato,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          interessiSelezionati.add(interesse);
                        } else {
                          interessiSelezionati.remove(interesse);
                        }
                      });
                    },
                    selectedColor: Colors.indigo.shade200,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selezionato ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Conferma Viaggio', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
