import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/viaggio.dart';
import '../utils/string_extensions.dart';

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
  late TextEditingController emozioniController;
  late TextEditingController costoController;

  TimeOfDay? orario;
  String categoria = 'attività';

  File? immagineSelezionata;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  final categorieDisponibili = ['attività', 'trasporto', 'pernottamento'];

  

  @override
  void initState() {
    super.initState();

    final att = widget.attivitaEsistente;
    titoloController = TextEditingController(text: att?.titolo ?? '');
    luogoController = TextEditingController(text: att?.luogo ?? '');
    descrizioneController = TextEditingController(text: att?.descrizione ?? '');
    emozioniController = TextEditingController(); // Nuovo campo
    costoController = TextEditingController(
      text: att?.costoStimato?.toStringAsFixed(2) ?? '',
    );

    if (att != null) {
      orario = TimeOfDay.fromDateTime(att.orario);
      categoria = att.categoria;
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
    emozioniController.dispose();
    costoController.dispose();
    super.dispose();
  }

  Future<void> selezionaImmagine() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => immagineSelezionata = File(picked.path));
    }
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

      final attivita = Attivita(
        id: widget.attivitaEsistente?.id ?? const Uuid().v4(),
        titolo: titoloController.text.trim(),
        descrizione: descrizioneController.text.trim(),
        orario: orarioCompleto,
        luogo: luogoController.text.trim(),
        completata: false, // rimosso campo modificabile
        generataDaIA: widget.attivitaEsistente?.generataDaIA ?? false,
        categoria: categoria,
        costoStimato: double.tryParse(costoController.text.replaceAll(',', '.')) ?? 0.0,
        emozioni: emozioniController.text.trim(), // <-- opzionale
        immaginePath: null, // da implementare in futuro
      );

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(widget.viaggio.userId)
          .collection('viaggi')
          .doc(widget.viaggio.id)
          .collection('attivita')
          .doc(attivita.id)
          .set({
        ...attivita.toJson(),
        'giorno': giornoKey,
      });

      if (!mounted) return;
      Navigator.pop(context, attivita);
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
    final isModifica = widget.attivitaEsistente != null;
    final data = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(widget.giorno);

    return Scaffold(
      appBar: AppBar(
        title: Text('${isModifica ? "Modifica" : "Nuova"} attività - $data'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: salvaAttivita),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Titolo
                TextFormField(
                  controller: titoloController,
                  decoration: const InputDecoration(
                    labelText: 'Titolo attività *',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 16),

                // Categoria
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoria *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categorieDisponibili
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.capitalize())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => categoria = val);
                  },
                ),
                const SizedBox(height: 16),

                // Luogo
                TextFormField(
                  controller: luogoController,
                  decoration: const InputDecoration(
                    labelText: 'Luogo (facoltativo)',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Costo
                TextFormField(
                  controller: costoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Costo stimato (€)',
                    prefixIcon: Icon(Icons.euro),
                  ),
                ),
                const SizedBox(height: 16),

                // Orario
                Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 8),
                    Text(
                      orario != null ? orario!.format(context) : 'Orario non selezionato',
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
                const SizedBox(height: 24),

                // Descrizione
                TextFormField(
                  controller: descrizioneController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Dettagli (facoltativi)',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Emozioni/pensieri
                TextFormField(
                  controller: emozioniController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Pensieri / emozioni',
                    prefixIcon: Icon(Icons.favorite_border),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Immagine (preview + bottone)
                if (immagineSelezionata != null)
                  Image.file(immagineSelezionata!, height: 120, fit: BoxFit.cover),
                OutlinedButton.icon(
                  onPressed: selezionaImmagine,
                  icon: const Icon(Icons.image),
                  label: const Text("Aggiungi immagine"),
                ),

                const SizedBox(height: 24),

                // Salva
                ElevatedButton.icon(
                  onPressed: salvaAttivita,
                  icon: const Icon(Icons.check),
                  label: Text(isModifica ? 'Salva modifiche' : 'Salva attività'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

