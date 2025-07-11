import 'package:flutter/material.dart';
import 'package:travel_sage/models/viaggio.dart';
import 'package:travel_sage/main.dart';
import 'package:intl/intl.dart';

class ModificaViaggioPage extends StatefulWidget {
  final Viaggio viaggio;
  final int index;

  const ModificaViaggioPage({super.key, required this.viaggio, required this.index});

  @override
  State<ModificaViaggioPage> createState() => _ModificaViaggioPageState();
}

class _ModificaViaggioPageState extends State<ModificaViaggioPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController destinazioneController;
  late TextEditingController budgetController;
  late DateTime startDate;
  late DateTime endDate;
  List<String> partecipanti = [];
  final TextEditingController _participantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    destinazioneController = TextEditingController(text: widget.viaggio.destinazione);
    budgetController = TextEditingController(text: widget.viaggio.budget);
    partecipanti = List.from(widget.viaggio.partecipanti);
    startDate = widget.viaggio.dataInizio;
    endDate = widget.viaggio.dataFine;
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
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

  void salvaModifiche() {
    if (_formKey.currentState!.validate() && partecipanti.isNotEmpty) {
      final viaggioModificato = widget.viaggio.copyWith(
        destinazione: destinazioneController.text.trim(),
        titolo: destinazioneController.text.trim(), // ✅ USA IL CONTROLLER QUI
        dataInizio: startDate,
        dataFine: endDate,
        budget: budgetController.text.trim(),
        partecipanti: List.from(partecipanti),
        confermato: false,
      );

      setState(() {
        viaggiBozza[widget.index] = viaggioModificato;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Viaggio aggiornato con successo'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa tutti i campi obbligatori')),
      );
    }
  }

  @override
  void dispose() {
    destinazioneController.dispose();
    budgetController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Modifica Viaggio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: destinazioneController,
                decoration: InputDecoration(
                  labelText: 'Destinazione',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Inizio',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(dateFormat.format(startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Fine',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(dateFormat.format(endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Budget per persona (€)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 32),

              Text('Partecipanti', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: partecipanti
                    .map((p) => Chip(
                          label: Text(p),
                          onDeleted: () {
                            setState(() {
                              partecipanti.remove(p);
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
                            partecipanti.add(val.trim());
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
                          partecipanti.add(_participantController.text.trim());
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
                  onPressed: salvaModifiche,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Salva modifiche'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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