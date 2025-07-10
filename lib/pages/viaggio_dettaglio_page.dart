import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:travel_sage/models/spesa.dart';
import 'package:travel_sage/models/viaggio.dart';
import 'package:travel_sage/utils/splitwise_logic.dart';

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
  List<Spesa> spese = [];

  final List<Tab> myTabs = <Tab>[
    const Tab(text: 'Itinerario'),
    const Tab(text: 'Pernottamenti'),
    const Tab(text: 'Riepilogo Costi'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _aggiungiSpesa() {

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

    showModalBottomSheet(
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
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    importo = val;
                    setModalState(() {
                      _importoInvalido = double.tryParse(val) == null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Selezione Pagatore
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
                      value: pagatore.isEmpty ? null : pagatore, // Aggiungi questa linea
                      items: widget.viaggio.partecipanti.map((p) {
                      return DropdownMenuItem(value: p,child: Text(p,style: TextStyle(
                      color: pagatore == p ? Colors.indigo : Colors.black, // Evidenzia selezione
                      fontWeight: pagatore == p ? FontWeight.bold : FontWeight.normal,
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
                
                // Coinvolti con indicatore errore
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
                
                // Pulsante Salva
                ElevatedButton(
                  onPressed: () {
                    // Validazione finale
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
                        descrizione: descrizione,
                        importo: double.parse(importo),
                        pagatore: pagatore,
                        coinvolti: List.from(selezionati),
                        data: DateTime.now(),
                      );
                      setState(() => spese.add(nuovaSpesa));
                      Navigator.pop(context);
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

  void _modificaSpesa(int index) {
    Spesa spesa = spese[index];
    String descrizione = spesa.descrizione;
    String importo = spesa.importo.toString();
    String pagatore = spesa.pagatore;
    List<String> selezionati = List.from(spesa.coinvolti);

    showModalBottomSheet(
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
                    'Modifica Spesa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Descrizione'),
                    controller: TextEditingController(text: descrizione),
                    onChanged: (val) => descrizione = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Importo (€)',
                      prefixText: '€',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    controller: TextEditingController(text: importo),
                    onChanged: (val) => importo = val,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Chi ha pagato'),
                    value: pagatore,
                    items: widget.viaggio.partecipanti
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      pagatore = val ?? '';
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Coinvolti',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (descrizione.isNotEmpty &&
                          importo.isNotEmpty &&
                          pagatore.isNotEmpty &&
                          selezionati.isNotEmpty) {
                        final spesaModificata = Spesa(
                          descrizione: descrizione,
                          importo: double.tryParse(importo) ?? 0.0,
                          pagatore: pagatore,
                          coinvolti: List.from(selezionati),
                          data: spesa.data,
                        );
                        setState(() {
                          spese[index] = spesaModificata;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Spesa modificata con successo')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Compila tutti i campi')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Salva Modifiche'),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _eliminaSpesa(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Elimina spesa'),
        content: const Text('Vuoi davvero eliminare questa spesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                spese.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Spesa eliminata')),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRiepilogoCosti() {
    if (spese.isEmpty) {
      return const Center(child: Text('Nessuna spesa registrata'));
    }

    final debiti = calcolaDebitiOttimizzati(spese);
    if (debiti.isEmpty) {
      return const Center(child: Text('Tutti i debiti sono saldati'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...debiti.map(
          (d) => ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: Text('${d['from']} deve a ${d['to']}'),
            trailing: Text('€${d['amount'].toStringAsFixed(2)}'),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Grafico spese per partecipante',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(height: 250, child: _buildPieChart()),
        const SizedBox(height: 32),
        Text(
          'Dettaglio spese',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        ...spese.asMap().entries.map(
          (entry) {
            int index = entry.key;
            Spesa spesa = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(spesa.descrizione),
                subtitle: Text(
                    '€${spesa.importo.toStringAsFixed(2)} - Pagata da ${spesa.pagatore}\nCoinvolti: ${spesa.coinvolti.join(', ')}\nData: ${spesa.data.toLocal().toString().split(' ')[0]}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _modificaSpesa(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminaSpesa(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    Map<String, double> totalePerPartecipante = {};
    for (var p in widget.viaggio.partecipanti) {
      totalePerPartecipante[p] =
          spese.where((s) => s.pagatore == p).fold(0.0, (sum, s) => sum + s.importo);
    }

    final colors = [
      Colors.indigo,
      Colors.deepPurple,
      Colors.pink,
      Colors.teal,
      Colors.orange,
      Colors.green,
      Colors.cyan,
      Colors.amber,
    ];

    final sections = <PieChartSectionData>[];
    int i = 0;
    totalePerPartecipante.forEach((partecipante, totale) {
      if (totale > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: totale,
            title: '${totale.toStringAsFixed(2)} €',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      i++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(touchCallback: (event, response) {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          const Center(child: Text('Sezione Itinerario - da implementare')),
          const Center(child: Text('Sezione Pernottamenti - da implementare')),
          _buildRiepilogoCosti(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _aggiungiSpesa,
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Spesa'),
      ),
    );
  }
}
