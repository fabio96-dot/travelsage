import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/viaggio.dart';
import 'aggiungi_attivita_page.dart';

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

class _GiornoItinerarioPageState extends State<GiornoItinerarioPage> {
  final TextEditingController titoloController = TextEditingController();
  final TextEditingController oraController = TextEditingController();
  final TextEditingController luogoController = TextEditingController();

  late List<Attivita> listaAttivita;

  @override
  void initState() {
    super.initState();
    listaAttivita = List.from(widget.viaggio.attivitaDelGiorno(widget.giorno) ?? []);
  }

  void aggiungiAttivita() {
    final titolo = titoloController.text.trim();
    final oraText = oraController.text.trim();

    if (titolo.isEmpty || oraText.isEmpty) return;

    final now = widget.giorno;
    final parts = oraText.split(':');
    final orario = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

    final nuova = Attivita(
      id: UniqueKey().toString(),
      titolo: titolo,
      descrizione: '',
      orario: orario,
      luogo: luogoController.text.trim(),
    );

    setState(() {
      listaAttivita.add(nuova);
      widget.viaggio.aggiungiAttivita(widget.giorno, nuova);
      titoloController.clear();
      oraController.clear();
      luogoController.clear();
    });
  }

@override
Widget build(BuildContext context) {
  final data = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(widget.giorno);
  final attivita = widget.viaggio.attivitaDelGiorno(widget.giorno) ?? [];

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
        : ListView.builder(
            itemCount: attivita.length,
            itemBuilder: (context, index) {
              final att = attivita[index];
              final orario = DateFormat.Hm().format(att.orario);
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
                  onTap: () {
                    // in futuro: dettagli attività
                  },
                ),
              );
            },
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
}