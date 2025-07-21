import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:travel_sage/models/spesa.dart';
import 'package:travel_sage/models/viaggio.dart';
import 'package:travel_sage/utils/splitwise_logic.dart';
import 'giorno_itinerario_page.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViaggioDettaglioPage extends StatefulWidget {
  final Viaggio viaggio;
  final int index;

  const ViaggioDettaglioPage({super.key, required this.viaggio, required this.index});

  @override
  _ViaggioDettaglioPageState createState() => _ViaggioDettaglioPageState();
}

class _ViaggioDettaglioPageState extends State<ViaggioDettaglioPage>
    with SingleTickerProviderStateMixin {
    late TabController _tabController;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Stato locale per la lista spese
    List<Spesa> _spese = [];


    final List<Tab> myTabs = <Tab>[
    const Tab(text: 'Itinerario'),
    const Tab(text: 'Pernottamenti'),
    const Tab(text: 'Riepilogo Costi'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
     _loadSpese();
  }

  Future<void> _loadSpese() async {
    final viaggioId = widget.viaggio.id;
    final snapshot = await _firestore
        .collection('viaggi')
        .doc(viaggioId)
        .collection('spese')
        .get();

    final speseList = snapshot.docs
        .map((doc) => Spesa.fromJson(doc.data()))
        .toList();

    setState(() {
      _spese = speseList;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Future<void> _aggiungiSpesa() async {

      if (widget.viaggio.partecipanti.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: const Text('Aggiungi partecipanti prima di inserire spese!'),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return;
  }

    String descrizione = '';
    String importo = '';
    String pagatore = '';
    List<String> selezionati = [];
    bool _importoInvalido = false;
    bool _pagatoreNonSelezionato = false;
    bool _nessunCoinvolto = false; 

  await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nuova Spesa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Descrizione',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    onChanged: (val) => descrizione = val,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Importo (€)',
                      prefixIcon: const Icon(Icons.euro),
                      border: const OutlineInputBorder(),
                      errorText: _importoInvalido ? 'Inserisci un numero valido' : null,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      importo = val;
                      setModalState(() {
                        _importoInvalido = double.tryParse(val) == null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Chi ha pagato',
                      border: const OutlineInputBorder(),
                      errorText: _pagatoreNonSelezionato ? 'Seleziona un pagatore' : null,
                      suffixIcon: pagatore.isNotEmpty
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Seleziona', style: TextStyle(color: Colors.grey)),
                        value: pagatore.isEmpty ? null : pagatore,
                        items: widget.viaggio.partecipanti.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              p,
                              style: TextStyle(
                                color: pagatore == p ? Colors.indigo : Colors.black,
                                fontWeight: pagatore == p
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          pagatore = val ?? '';
                          setModalState(() {
                            _pagatoreNonSelezionato = val == null;
                          });
                        },
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Coinvolti', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (_nessunCoinvolto)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Seleziona almeno un coinvolto',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  Wrap(
                    spacing: 8,
                    children: widget.viaggio.partecipanti.map((p) {
                      final selected = selezionati.contains(p);
                      return FilterChip(
                        label: Text(p),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              selezionati.add(p);
                            } else {
                              selezionati.remove(p);
                            }
                            _nessunCoinvolto = selezionati.isEmpty;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      bool valid = true;
                      if (descrizione.isEmpty) valid = false;
                      if (double.tryParse(importo) == null) {
                        setModalState(() => _importoInvalido = true);
                        valid = false;
                      }
                      if (pagatore.isEmpty) {
                        setModalState(() => _pagatoreNonSelezionato = true);
                        valid = false;
                      }
                      if (selezionati.isEmpty) {
                        setModalState(() => _nessunCoinvolto = true);
                        valid = false;
                      }

                      if (valid) {
                        final nuovaSpesa = Spesa(
                          id: UniqueKey().toString(),
                          descrizione: descrizione,
                          importo: double.parse(importo),
                          pagatore: pagatore,
                          coinvolti: List.from(selezionati),
                          data: DateTime.now(),
                        );

                        // Salva su Firestore
                        final speseRef = _firestore
                            .collection('viaggi')
                            .doc(widget.viaggio.id)
                            .collection('spese');
                        await speseRef.doc(nuovaSpesa.id).set(nuovaSpesa.toJson());

                        setState(() {
                          _spese.add(nuovaSpesa);
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Spesa aggiunta con successo!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text('Salva Spesa', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }


Future<void> _modificaSpesa(int index) async {
    final spesa = _spese[index];
    String descrizione = spesa.descrizione;
    String importo = spesa.importo.toString();
    String pagatore = spesa.pagatore;
    List<String> selezionati = List.from(spesa.coinvolti);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Modifica Spesa',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Descrizione',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      initialValue: descrizione,
                      onChanged: (val) => descrizione = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Importo (€)',
                        border: OutlineInputBorder(),
                        prefixText: '€',
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      initialValue: importo,
                      onChanged: (val) => importo = val,
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Chi ha pagato',
                        border: const OutlineInputBorder(),
                        suffixIcon: pagatore.isNotEmpty
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: pagatore,
                          items: widget.viaggio.partecipanti.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: pagatore == p ? Colors.green : Colors.black,
                                  fontWeight: pagatore == p
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              pagatore = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Coinvolti:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.viaggio.partecipanti.map((p) {
                        final selected = selezionati.contains(p);
                        return FilterChip(
                          label: Text(p),
                          selected: selected,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selezionati.add(p);
                              } else {
                                selezionati.remove(p);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (descrizione.isNotEmpty &&
                                  importo.isNotEmpty &&
                                  pagatore.isNotEmpty &&
                                  selezionati.isNotEmpty) {
                                final spesaModificata = Spesa(
                                  id: spesa.id,
                                  descrizione: descrizione,
                                  importo: double.tryParse(importo) ?? 0.0,
                                  pagatore: pagatore,
                                  coinvolti: List.from(selezionati),
                                  data: spesa.data,
                                );

                                // Aggiorna Firestore
                                final speseRef = _firestore
                                    .collection('viaggi')
                                    .doc(widget.viaggio.id)
                                    .collection('spese');
                                await speseRef
                                    .doc(spesaModificata.id)
                                    .set(spesaModificata.toJson());

                                setState(() {
                                  _spese[index] = spesaModificata;
                                });

                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Salva'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

 Future<void> _eliminaSpesa(int index) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Conferma eliminazione'),
          content: const Text('Vuoi davvero eliminare questa spesa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (conferma == true) {
      final spesaId = _spese[index].id;
      final speseRef = _firestore
          .collection('viaggi')
          .doc(widget.viaggio.id)
          .collection('spese');

      await speseRef.doc(spesaId).delete();

      setState(() {
        _spese.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spesa eliminata con successo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


Widget _buildRiepilogoCosti() {
  final totaleSpese = _spese.fold(0.0, (sum, s) => sum + s.importo);
  final partecipanti = widget.viaggio.partecipanti;

  final spesePerPartecipante = <String, double>{};
  for (final p in partecipanti) {
    spesePerPartecipante[p] = _spese
      .where((s) => s.pagatore == p)
      .fold(0.0, (sum, s) => sum + s.importo);
  }

  final quotaEqua = partecipanti.isEmpty ? 0.0 : totaleSpese / partecipanti.length;

  final transactions = SplitwiseLogic.calculateOptimizedTransactions(
    _spese, // usa _spese, non widget.viaggio.spese
    partecipanti,
  );
  
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(), // Fisica di scrolling più naturale
    padding: const EdgeInsets.only(bottom: 100), // Spazio extra in fondo
    child: Column(
      children: [
        // Riepilogo rapido
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Riepilogo Spese',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Totale speso:'),
                    Text(
                      '€${totaleSpese.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Media per persona:'),
                    Text(
                      '€${quotaEqua.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Grafico
        const Padding(
          padding: EdgeInsets.only(right: 16, left: 16, top: 10, bottom: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Spese per partecipante',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(
          height: 260,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildBarChart(spesePerPartecipante),
          ),
        ),

        // Transazioni
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Riepilogo debiti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tutti i conti sono in pari!'),
          )
        else
          ...transactions.map((t) => _buildTransactionTile(t)),

        // Lista spese
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dettaglio spese',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ..._spese.map((spesa) => _buildExpenseTile(spesa)),
      ],
    ),
  );
}

Widget _buildBarChart(Map<String, double> data) {
  final maxValue = data.values.fold(0.0, (max, value) => value > max ? value : max);
  final interval = _calculateInterval(maxValue);
  final needCompactFormat = maxValue > 1000;

  // Arrotonda il massimo al multiplo dell'intervallo successivo
  final fixedMaxY = ((maxValue / interval).ceil() * interval).toDouble();

  return BarChart(
    BarChartData(
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: needCompactFormat ? 42 : 48,
            interval: interval,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Text(
                  _formatValue(value, needCompactFormat),
                  style: TextStyle(
                    fontSize: needCompactFormat ? 9 : 10,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                final name = data.keys.elementAt(index);
                final displayName = name.length > 8
                    ? '${name.substring(0, 6)}..'
                    : name;
                return Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: data.entries.map((entry) {
        final index = data.keys.toList().indexOf(entry.key);
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: Colors.primaries[index % Colors.primaries.length],
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      minY: 0,
      maxY: fixedMaxY,
    ),
  );
}

// ✅ Formattazione compatta per valori grandi
String _formatValue(double value, bool compact) {
  if (!compact) return '€${value.toInt()}';
  if (value >= 1000000) {
    return '€${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '€${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
  } else {
    return '€${value.toInt()}';
  }
}

// ✅ Logica intervallo coerente
double _calculateInterval(double maxValue) {
  if (maxValue <= 500) return 100;
  if (maxValue <= 2000) return 200;
  if (maxValue <= 5000) return 500;
  if (maxValue <= 10000) return 1000;
  if (maxValue <= 50000) return 5000;
  return 10000;
}

Widget _buildTransactionTile(Map<String, dynamic> transaction) {
  final amount = transaction['amount'] as double;
  final formattedAmount = NumberFormat.currency(
    symbol: '€',
    decimalDigits: amount % 1 == 0 ? 0 : 2,
  ).format(amount);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.compare_arrows, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${transaction['from']} → ${transaction['to']}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          formattedAmount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _buildExpenseTile(Spesa spesa) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      title: Text(spesa.descrizione),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pagato da: ${spesa.pagatore}'),
          Text('Importo: €${spesa.importo.toStringAsFixed(2)}'),
          Text('Coinvolti: ${spesa.coinvolti.join(', ')}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _modificaSpesa(_spese.indexOf(spesa)),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _eliminaSpesa(_spese.indexOf(spesa)),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildItinerarioTab() {
  final giorniTotali = widget.viaggio.dataFine.difference(widget.viaggio.dataInizio).inDays + 1;

  return ListView.builder(
    itemCount: giorniTotali,
    itemBuilder: (context, index) {
      final giorno = widget.viaggio.dataInizio.add(Duration(days: index));
      final giornoFormat = DateFormat('EEEE dd MMMM yyyy', 'it_IT').format(giorno);
      
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text('Giorno ${index + 1}'),
          subtitle: Text(giornoFormat),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => GiornoItinerarioPage(
                  giorno: giorno,
                  viaggio: widget.viaggio, 
                ),
              ),
            );// per ora lista vuota, in futuro salvata nel modello
          },
        ),
      );
    },
  );
  }

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      Navigator.pop(context, true);  // ritorna true al chiamante
      return false; // blocca il pop automatico
    },
  child: Scaffold(
    appBar: AppBar(
      title: Hero(
        tag: 'viaggio_${widget.viaggio.destinazione}_${widget.index}',
        child: Material(
          type: MaterialType.transparency,
          child: Text(widget.viaggio.destinazione),
        ),
      ),
      bottom: TabBar(controller: _tabController, tabs: myTabs),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        _buildItinerarioTab(),
        const Center(child: Text('Sezione Pernottamenti - da implementare')),
        _buildRiepilogoCosti(),
      ],
    ),
    floatingActionButton: Padding(
      padding: const EdgeInsets.only(bottom: 16), // Spazio sotto il pulsante
      child: FloatingActionButton.extended(
            onPressed: () async {
      await _aggiungiSpesa();
      },
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Spesa'),
      ),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  )
  );
}
}
