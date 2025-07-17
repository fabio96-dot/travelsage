import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/viaggio.dart';
import 'aggiungi_attivita_page.dart';
import '../../services/firestore_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

class GiornoItinerarioPage extends StatefulWidget {
  final DateTime giorno;
  final Viaggio viaggio;
  

  const GiornoItinerarioPage({
    Key? key,
    required this.giorno,
    required this.viaggio,
  }) : super(key: key);

  @override
  State<GiornoItinerarioPage> createState() => _GiornoItinerarioPageState();
}

class _GiornoItinerarioPageState extends State<GiornoItinerarioPage> with TickerProviderStateMixin {
  late List<Attivita> listaAttivita;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  

  @override
  void initState() {
    super.initState();
    listaAttivita = List.from(widget.viaggio.attivitaDelGiorno(
      DateTime(widget.giorno.year, widget.giorno.month, widget.giorno.day),
    ) ?? []);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  
void _modificaAttivita(Attivita attivita, int index) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AggiungiAttivitaPage(
        giorno: widget.giorno,
        viaggio: widget.viaggio,
        attivitaEsistente: attivita,
      ),
    ),
  );
  
  if (result != null && result is Attivita) {
    setState(() {
      widget.viaggio.modificaAttivita(widget.giorno, attivita.id, result);
    });

    await FirestoreService().saveViaggio(widget.viaggio); // 👈 salva su Firestore

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Attività modificata con successo!"),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

void _eliminaAttivita(int index) async {
  final attivitaDaEliminare = widget.viaggio.attivitaDelGiorno(widget.giorno)?[index];
  if (attivitaDaEliminare == null) return;

  final conferma = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conferma eliminazione'),
      content: const Text('Sei sicuro di voler eliminare questa attività?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Elimina', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (conferma == true) {
    setState(() {
      widget.viaggio.rimuoviAttivita(widget.giorno, attivitaDaEliminare.id);
    });

    await FirestoreService().saveViaggio(widget.viaggio); // 👈 salva su Firestore

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Attività eliminata con successo!"),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Map<String, double> calcolaCostiPerCategoria(List<Attivita> attivita) {
final costi = <String, double>{};

for (final a in attivita) {
  final cat = a.categoria.toLowerCase();
  final costo = a.costoStimato ?? 0.0;
  costi[cat] = (costi[cat] ?? 0.0) + costo;
}

return costi;
}


  @override
  Widget build(BuildContext context) {
    final data = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(widget.giorno);
    final attivita = List<Attivita>.from(widget.viaggio.attivitaDelGiorno(widget.giorno) ?? []);
    final costi = calcolaCostiPerCategoria(attivita);

    final icons = {
      'pernottamento': Icons.hotel,
      'trasporto': Icons.directions_car,
      'attività': Icons.local_activity,
    };

    final colori = {
      'pernottamento': Colors.deepPurple,
      'trasporto': Colors.teal,
      'attività': Colors.orange,
    };

    print('Attività per giorno ${widget.giorno}: ${attivita.length}');
    for (var a in attivita) {
      print(' - ${a.titolo} alle ${a.orario}');
    }
    attivita.sort((a, b) => a.orario.compareTo(b.orario));

    final riassuntoCosti = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Costi stimati del giorno",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: costi.entries.map((entry) {
                  final icon = icons[entry.key] ?? Icons.category;
                  final color = colori[entry.key] ?? Colors.grey;
                  return Chip(
                    backgroundColor: color.withOpacity(0.1),
                    avatar: Icon(icon, size: 18, color: color),
                    label: Text(
                      "${entry.key.capitalize()}: €${entry.value.toStringAsFixed(2)}",
                      style: TextStyle(color: color.shade700, fontWeight: FontWeight.w500),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

          // 👇 Aggiungi questo blocco per il totale
              Row(
                children: [
                  const Icon(Icons.summarize, size: 18, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    "Totale: €${costi.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Itinerario - $data'),
      ),
      body: attivita.isEmpty
      ? const Center(
        child: Text(
          'Non ci sono attività programmate.',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      )
      : Column(
        children: [
          riassuntoCosti,
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                key: ValueKey<int>(attivita.length),
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: attivita.length,
                itemBuilder: (context, index) {
                  final att = attivita[index];
                  final orario = DateFormat.Hm().format(att.orario);

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 40.0,
                      curve: Curves.easeOut,
                      child: FadeInAnimation(
                        child: _buildListItem(att, index, orario),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final nuova = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AggiungiAttivitaPage(
                giorno: widget.giorno,
                viaggio: widget.viaggio,
              ),
            ),
          );

          if (nuova != null && nuova is Attivita) {
            setState(() {
              widget.viaggio.aggiungiAttivita(widget.giorno, nuova);
            });

            await FirestoreService().saveViaggio(widget.viaggio); // 👈 salva su Firestore

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Attività aggiunta con successo!"),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Aggiungi attività"),
      ),
    );
  }

Widget _buildListItem(Attivita att, int index, String orario) {
  final costo = att.costoStimato != null ? '€${att.costoStimato!.toStringAsFixed(2)}' : 'N/A';
  final categoria = att.categoria.isNotEmpty ? att.categoria.capitalize() : 'Attività';

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(att.titolo)),
              if (att.generataDaIA)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Tooltip(
                    message: 'Generata dall’assistente AI',
                    child: Icon(Icons.smart_toy, size: 18, color: Colors.deepPurple),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '💶 $costo   •   🏷️ $categoria',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
      subtitle: Text('$orario - ${att.luogo ?? "Nessun luogo"}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _modificaAttivita(att, index),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _eliminaAttivita(index),
          ),
        ],
      ),
    ),
  );
}
}