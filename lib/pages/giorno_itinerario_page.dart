import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/viaggio.dart';
import 'aggiungi_attivita_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
    listaAttivita = List.from(widget.viaggio.attivitaDelGiorno(widget.giorno) ?? []);

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Attività eliminata con successo!"),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final data = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(widget.giorno);
    final attivita = List<Attivita>.from(widget.viaggio.attivitaDelGiorno(widget.giorno) ?? [])
    ..sort((a, b) => a.orario.compareTo(b.orario));

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
    : AnimationLimiter(
        child: ListView.builder(
          key: ValueKey<int>(attivita.length), // fa triggerare l'animazione se cambia la lista
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
      title: Text(att.titolo),
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
      onTap: () {
        // dettagli attività
      },
    ),
  );
}
}