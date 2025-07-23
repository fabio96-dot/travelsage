import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prenotazione.dart';
import '../../models/viaggio.dart';

class AggiungiPrenotazionePage extends StatefulWidget {
  final Viaggio viaggio;
  final Prenotazione? prenotazione;

  const AggiungiPrenotazionePage({
    Key? key,
    required this.viaggio,
    this.prenotazione,
  }) : super(key: key);

  @override
  State<AggiungiPrenotazionePage> createState() => _AggiungiPrenotazionePageState();
}

class _AggiungiPrenotazionePageState extends State<AggiungiPrenotazionePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titoloController;
  late TextEditingController _luogoController;
  late TextEditingController _descrizioneController;
  late TextEditingController _linkController;
  late TextEditingController _costoController;

  DateTime? _data;
  String _categoria = 'Alloggio';

  final List<String> _categorie = ['Alloggio', 'Trasporto', 'Attività', 'Altro'];

  @override
  void initState() {
    super.initState();
    final p = widget.prenotazione;

    _titoloController = TextEditingController(text: p?.titolo ?? '');
    _luogoController = TextEditingController(text: p?.luogo ?? '');
    _descrizioneController = TextEditingController(text: p?.descrizione ?? '');
    _linkController = TextEditingController(text: p?.link ?? '');
    _costoController = TextEditingController(text: p?.costo?.toString() ?? '');
    _data = p?.data ?? widget.viaggio.dataInizio;
    _categoria = p?.categoria ?? 'Alloggio';
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _luogoController.dispose();
    _descrizioneController.dispose();
    _linkController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  String normalizzaLink(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
  }

  Future<void> _selectData(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = widget.viaggio.dataInizio;
    final lastDate = widget.viaggio.dataFine;

    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _data = picked;
      });
    }
  }

  void _salvaPrenotazione() {
    if (!_formKey.currentState!.validate()) return;

    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una data valida')),
      );
      return;
    }

    final double? costo = double.tryParse(_costoController.text.replaceAll(',', '.'));

    final nuovaPrenotazione = Prenotazione(
      id: widget.prenotazione?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titolo: _titoloController.text.trim(),
      luogo: _luogoController.text.trim(),
      descrizione: _descrizioneController.text.trim(),
      categoria: _categoria,
      data: _data!,
      link: normalizzaLink(_linkController.text),
      costo: costo,
      immagineUrl: null, // rimosso effettivamente, per compatibilità col model
    );

    Navigator.pop(context, nuovaPrenotazione);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prenotazione == null ? 'Aggiungi Prenotazione' : 'Modifica Prenotazione'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _salvaPrenotazione,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titoloController,
                decoration: const InputDecoration(labelText: 'Titolo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci un titolo' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _luogoController,
                decoration: const InputDecoration(labelText: 'Luogo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci un luogo' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categorie
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoria = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descrizioneController,
                decoration: const InputDecoration(labelText: 'Descrizione (opzionale)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link prenotazione (opzionale)',
                  hintText: 'booking.com/hotel...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costoController,
                decoration: const InputDecoration(
                  labelText: 'Costo stimato (opzionale)',
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    _data != null ? DateFormat('dd/MM/yyyy').format(_data!) : 'Seleziona una data',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _selectData(context),
                    child: const Text('Scegli data'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


