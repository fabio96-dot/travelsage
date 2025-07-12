import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/viaggio.dart';

class AggiungiAttivitaPage extends StatefulWidget {
  final DateTime giorno;
  final Viaggio viaggio;

  const AggiungiAttivitaPage({
    super.key,
    required this.giorno,
    required this.viaggio,
  });

  @override
  State<AggiungiAttivitaPage> createState() => _AggiungiAttivitaPageState();
}

class _AggiungiAttivitaPageState extends State<AggiungiAttivitaPage> {
  final _formKey = GlobalKey<FormState>();
  final titoloController = TextEditingController();
  final luogoController = TextEditingController();
  TimeOfDay? orario;

void salvaAttivita() {
  if (_formKey.currentState!.validate() && orario != null) {
    final now = widget.giorno;
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      orario!.hour,
      orario!.minute,
    );

    final nuova = Attivita(
      id: const Uuid().v4(),
      titolo: titoloController.text.trim(),
      descrizione: '',
      orario: dateTime,
      luogo: luogoController.text.trim(),
    );

    Navigator.pop(context, nuova); // 🔁 ritorna l'attività creata
  }
}

  @override
  Widget build(BuildContext context) {
    final data = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(widget.giorno);

    return Scaffold(
      appBar: AppBar(title: Text('Nuova attività - $data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titoloController,
                decoration: const InputDecoration(
                  labelText: 'Titolo attività',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Inserisci un titolo' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: luogoController,
                decoration: const InputDecoration(
                  labelText: 'Luogo (facoltativo)',
                  prefixIcon: Icon(Icons.place),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 8),
                  Text(orario == null
                      ? 'Orario non selezionato'
                      : 'Orario: ${orario!.format(context)}'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => orario = picked);
                      }
                    },
                    child: const Text("Scegli orario"),
                  )
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: salvaAttivita,
                icon: const Icon(Icons.add),
                label: const Text("Salva attività"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}