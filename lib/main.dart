import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'core/config/env.dart';
import 'widgets/app_initializer.dart';
import 'pages/diario/Diary_Page.dart';
import '../widgets/skeleton_loader.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:js' as js;
import 'app_wrapper.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mostra immediatamente lo splash
  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));

  // Inizializza l'app in background
  _initializeAppAsync();
}

Future<void> _initializeAppAsync() async {
  try {
    // Carica le configurazioni
    if (kIsWeb) {
      await _waitForEnvJs();
    } else {
      await dotenv.load(fileName: '.env');
    }

    // Inizializza Firebase
    await Firebase.initializeApp(
      options: kIsWeb ? _getWebFirebaseOptions() : DefaultFirebaseOptions.currentPlatform,
    );

    // Configura Crashlytics solo per mobile
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }

    // Inizializza Google Fonts
    await GoogleFonts.pendingFonts([GoogleFonts.roboto()]);

    // Attendi 1 secondo per lo splash screen
    await Future.delayed(const Duration(seconds: 1));

    // Registra l'apertura dell'app (funziona sia su web che mobile)
    await FirebaseAnalytics.instance.logAppOpen();

    // Avvia l'app principale
    runApp(const AppWrapper());
  } catch (e, stack) {
    // Registra l'errore su Crashlytics (solo mobile)
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.recordError(e, stack);
    }
    
    // Mostra la schermata di errore
    _runErrorApp(e.toString());
  }
}

void _runErrorApp(String error) {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 20),
                Text('Errore durante l\'inizializzazione:', 
                     style: GoogleFonts.roboto(fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    error,
                    style: GoogleFonts.roboto(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () => main(), // Riavvia l'app
                  child: Text('Riprova', style: GoogleFonts.roboto(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
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

Future<void> _waitForEnvJs() async {
  const maxAttempts = 50; // 5 secondi totali (50 * 100ms)
  int attempts = 0;
  
  while (js.context['flutterConfig'] == null && attempts < maxAttempts) {
    await Future.delayed(const Duration(milliseconds: 100));
    attempts++;
  }
  
  if (js.context['flutterConfig'] == null) {
    throw Exception('Configurazione web non caricata entro il timeout');
  }
}

FirebaseOptions _getWebFirebaseOptions() {
  final config = js.context['flutterConfig'];
  if (config == null) throw Exception('env.js non caricato!');

  return FirebaseOptions(
    apiKey: config['apiKey'],
    authDomain: config['authDomain'],
    projectId: config['projectId'],
    storageBucket: config['storageBucket'],
    messagingSenderId: config['messagingSenderId'],
    appId: config['appId'],
    measurementId: config['measurementId'],
  );
}


List<Viaggio> viaggiBozza = [];

class TravelSageApp extends StatelessWidget {
  const TravelSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TravelSage',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
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

  void _submit() {
    if (_formKey.currentState!.validate() &&
      startDate != null &&
      endDate != null &&
      participants.isNotEmpty) {

    final nuovoViaggio = Viaggio(
      id: UniqueKey().toString(), // Genera un ID univoco
      titolo: 'Nuovo Viaggio', // Aggiungi un titolo di default
      destinazione: destination.trim(),
      dataInizio: startDate!,
      dataFine: endDate!,
      budget: budget.trim(),
      partecipanti: List.from(participants),
      confermato: false,
      spese: [], // Lista vuota di spese
      archiviato: false, // Valore di default
      note: null, // Note opzionali
      itinerario: {}, // Mappa vuota per l'itinerario
    );

    widget.onViaggioCreato(nuovoViaggio);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viaggio creato con successo')),
    );

    final int newIndex = viaggiBozza.length - 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViaggioDettaglioPage(
          viaggio: nuovoViaggio,
          index: newIndex,
        ),
      ),
    );
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

class _TripsPageState extends State<TripsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController; // Aggiungi il controller
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, // Numero di tab
      vsync: this, // Richiede SingleTickerProviderStateMixin
    );
    _tabController.addListener(_handleTabSelection);
    Future.delayed(Duration.zero, _archiviaViaggiScaduti);
  }

  void _handleTabSelection() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Importante per evitare memory leak
    super.dispose();
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
          onPressed: () {
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

  void _archiviaViaggiScaduti() {
    final oggi = DateTime.now();
    final viaggiArchiviati = <String>[];

    setState(() {
      for (int i = 0; i < viaggiBozza.length; i++) {
        final viaggio = viaggiBozza[i];
        final dataFine = viaggio.dataFine;

        // Archivia solo viaggi confermati e non già archiviati
        final nonArchiviato = !viaggio.archiviato;
        final confermato = viaggio.confermato;
        final scaduto = dataFine.isBefore(oggi);

        if (confermato && nonArchiviato && scaduto) {
        viaggiBozza[i] = viaggio.copyWith(archiviato: true);
        TravelState.viaggiDaArchiviare.add({'destinazione': viaggio.destinazione});
      }
    }
  });

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
                    child: const Text('OK')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formatter = DateFormat('dd/MM/yyyy');

    final viaggiNonArchiviati = viaggiBozza.where((v) => !v.archiviato).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Viaggi salvati'),
        bottom: TabBar( 
          controller: _tabController, // Assegna il controller
          tabs: const [
            Tab(icon: Icon(Icons.card_travel)),  // Parentesi chiusa aggiunta
            Tab(icon: Icon(Icons.calendar_today)), // Parentesi chiusa aggiunta
          ],
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
        ),
      ),
      body: _buildTabContent(context, viaggiNonArchiviati),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: widget.onAddNewTrip,
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add),
              tooltip: 'Aggiungi nuovo viaggio',
            )
          : null,
    );
  }

  Widget _buildTabContent(BuildContext context, List<Viaggio> viaggiNonArchiviati) {
    if (_currentTabIndex == 0) {
      return _buildViaggiTab(context, viaggiNonArchiviati);
    } else {
      return _buildItinerariTab(context);
    }
  }

  Widget _buildViaggiTab(BuildContext context, List<Viaggio> viaggiNonArchiviati) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    return viaggiNonArchiviati.isEmpty
        ? const SkeletonLoader()
        : Padding(
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
      color: Theme.of(context).cardColor,
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
          // Intestazione con titolo e pulsanti
          Row(
            children: [
              Expanded(
                child: Text(
                  viaggio.titolo.isNotEmpty ? viaggio.titolo : viaggio.destinazione,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!viaggio.confermato)
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      viaggiBozza[originalIndex] = viaggio.copyWith(confermato: true);
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, originalIndex),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Dettagli viaggio
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                viaggio.destinazione,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('dd/MM/yy').format(viaggio.dataInizio)} - ${DateFormat('dd/MM/yy').format(viaggio.dataFine)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Stato
          Row(
            children: [
              Icon(
                viaggio.confermato ? Icons.check_circle : Icons.edit,
                size: 16,
                color: viaggio.confermato ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                viaggio.confermato ? 'Confermato' : 'Bozza',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: viaggio.confermato ? Colors.green : Colors.orange,
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

  Widget _buildItinerariTab(BuildContext context) {
    final viaggiConItinerario = viaggiBozza
        .where((v) => v.confermato && !v.archiviato && v.itinerario.isNotEmpty)
        .toList();

    if (viaggiConItinerario.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessun itinerario disponibile',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Conferma un viaggio e aggiungi attività per visualizzare gli itinerari',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viaggiConItinerario.length,
      itemBuilder: (context, index) {
        final viaggio = viaggiConItinerario[index];
        final giorniViaggio = _getDaysInRange(viaggio.dataInizio, viaggio.dataFine);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(viaggio.titolo),
            subtitle: Text('${viaggio.destinazione} • ${DateFormat('dd/MM/yyyy').format(viaggio.dataInizio)} - ${DateFormat('dd/MM/yyyy').format(viaggio.dataFine)}'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: giorniViaggio.map((giorno) {
                    final attivita = viaggio.attivitaDelGiorno(giorno) ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            DateFormat('EEEE, d MMMM', 'it_IT').format(giorno),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (attivita.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Nessuna attività programmata'),
                          )
                        else
                          ...attivita.map((a) => _buildAttivitaCard(a)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViaggioDettaglioPage(
                          viaggio: viaggio,
                          index: viaggiBozza.indexOf(viaggio),
                        ),
                      ),
                    );
                  },
                  child: const Text('Vedi dettagli viaggio'),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttivitaCard(Attivita attivita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: attivita.completata ? Colors.green : Colors.blue,
          child: Icon(
            attivita.completata ? Icons.check : Icons.access_time,
            color: Colors.white,
          ),
        ),
        title: Text(attivita.titolo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attivita.descrizione),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('HH:mm').format(attivita.orario)}${attivita.luogo != null ? ' • ${attivita.luogo}' : ''}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Qui puoi aggiungere la logica per modificare l'attività
          },
        ),
      ),
    );
  }

  List<DateTime> _getDaysInRange(DateTime startDate, DateTime endDate) {
    final days = <DateTime>[];
    for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }
}