import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/viaggio.dart';

class AggiungiAttivitaPage extends ConsumerStatefulWidget {
  final DateTime giorno;
  final Viaggio viaggio;
  final Attivita? attivitaEsistente;

  const AggiungiAttivitaPage({
    super.key,
    required this.giorno,
    required this.viaggio,
    this.attivitaEsistente,
  });

  @override
  ConsumerState<AggiungiAttivitaPage> createState() => _AggiungiAttivitaPageState();
}

class _AggiungiAttivitaPageState extends ConsumerState<AggiungiAttivitaPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titoloController;
  late TextEditingController luogoController;
  late TextEditingController descrizioneController;
  TimeOfDay? orario;
  late bool completata;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    titoloController = TextEditingController(text: widget.attivitaEsistente?.titolo ?? '');
    luogoController = TextEditingController(text: widget.attivitaEsistente?.luogo ?? '');
    descrizioneController = TextEditingController(text: widget.attivitaEsistente?.descrizione ?? '');
    completata = widget.attivitaEsistente?.completata ?? false;

    if (widget.attivitaEsistente != null) {
      orario = TimeOfDay.fromDateTime(widget.attivitaEsistente!.orario);
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    titoloController.dispose();
    luogoController.dispose();
    descrizioneController.dispose();
    super.dispose();
  }

  Future<void> salvaAttivita() async {
    if (_formKey.currentState!.validate() && orario != null) {
      final giornoKey = DateFormat('yyyy-MM-dd').format(widget.giorno);

      final orarioCompleto = DateTime(
        widget.giorno.year,
        widget.giorno.month,
        widget.giorno.day,
        orario!.hour,
        orario!.minute,
      );

      final nuovaAttivita = Attivita(
        id: widget.attivitaEsistente?.id ?? const Uuid().v4(),
        titolo: titoloController.text.trim(),
        descrizione: descrizioneController.text.trim(),
        orario: orarioCompleto,
        luogo: luogoController.text.trim(),
        completata: completata,
        generataDaIA: widget.attivitaEsistente?.generataDaIA ?? false,
        categoria: widget.attivitaEsistente?.categoria ?? 'attivita',
        costoStimato: widget.attivitaEsistente?.costoStimato ?? 0.0,
      );

      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection('users')
          .doc(widget.viaggio.userId)
          .collection('viaggi')
          .doc(widget.viaggio.id)
          .collection('attivita')
          .doc(nuovaAttivita.id)
          .set({
        ...nuovaAttivita.toJson(),
        'giorno': giornoKey, // 🔥 per filtrare nel provider
      });

      if (!mounted) return;
      Navigator.pop(context);
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
    final isModifica = widget.attivitaEsistente != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${isModifica ? 'Modifica' : 'Nuova'} attività - $data'),
        actions: [
          if (isModifica)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: salvaAttivita,
            ),
        ],
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
                  color: Theme.of(context).cardColor,
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
                      decoration: const InputDecoration(
                        labelText: 'Titolo attività *',
                        prefixIcon: Icon(Icons.edit),
                      ),
                      validator: (value) => value!.isEmpty ? 'Scrivi un titolo' : null,
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
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: orario ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() => orario = picked);
                            }
                          },
                          child: const Text("Scegli orario"),
                        ),
                      ],
                    ),
                    if (isModifica) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Attività completata'),
                        value: completata,
                        onChanged: (value) {
                          setState(() => completata = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: salvaAttivita,
                      icon: const Icon(Icons.check),
                      label: Text(
                        isModifica ? 'Salva modifiche' : 'Salva attività',
                        style: const TextStyle(fontSize: 16),
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
