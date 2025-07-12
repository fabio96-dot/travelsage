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

class _AggiungiAttivitaPageState extends State<AggiungiAttivitaPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final titoloController = TextEditingController();
  final luogoController = TextEditingController();
  final descrizioneController = TextEditingController();
  TimeOfDay? orario;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
        descrizione: descrizioneController.text.trim(),
        orario: dateTime,
        luogo: luogoController.text.trim(),
      );

      Navigator.pop(context, nuova);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa i campi obbligatori e seleziona un orario."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(widget.giorno);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ supporta dark mode
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Nuova attività - $data'),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, // ✅ supporta dark mode
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: titoloController,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Titolo attività *',
                        prefixIcon: Icon(Icons.edit),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Scrivi un titolo' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: luogoController,
                      decoration: const InputDecoration(
                        labelText: 'Luogo (facoltativo)',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descrizioneController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Dettagli (facoltativi)',
                        hintText: 'Es. colazione sulla terrazza...',
                        prefixIcon: Icon(Icons.notes),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        Text(
                          orario == null
                              ? 'Orario non selezionato'
                              : orario!.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,     // ✅ usa primary dinamico
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,   // ✅ contrasto leggibile
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: salvaAttivita,
                      icon: const Icon(Icons.check),
                      label: const Text(
                        "Salva attività",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}