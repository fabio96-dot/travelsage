import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiApi {
  final GenerativeModel model;

  GeminiApi()
      : model = GenerativeModel(
          // Modifica qui - usa 'gemini-pro' invece di 'gemini-2.0'
          model: 'gemini-2.0-flash',
          apiKey: dotenv.env['GEMINI_API_KEY']!,
          // Configurazioni aggiuntive consigliate
          generationConfig: GenerationConfig(
            temperature: 0,
            maxOutputTokens: 8000,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          ],
        );

  Future<String> generaItinerario({
    required String destinazione,
    required String partenza,
    required DateTime dataInizio,
    required DateTime dataFine,
    required String budget,
    required List<String> interessi,
    required String mezzoTrasporto,
    required int attivitaGiornaliere,
    required double raggioKm,
    required double etaMedia,
    required String tipologiaViaggiatore,
    required String profilo,
  }) async {
    if (dataFine.isBefore(dataInizio)) {
      throw ArgumentError('La data finale non può essere prima di quella iniziale');
    }

    final giorni = dataFine.difference(dataInizio).inDays + 1;
    final dateFormatter = DateFormat('dd/MM/yyyy');

final prompt = '''
Genera solo un oggetto JSON valido per questo viaggio. Non includere spiegazioni o testo aggiuntivo.

Viaggio a: $destinazione
partenza da: $partenza
Date: ${dateFormatter.format(dataInizio)} - ${dateFormatter.format(dataFine)} ($giorni giorni)
Budget: $budget €
Interessi: ${interessi.join(', ')}
Mezzo di trasporto: $mezzoTrasporto
Attività giornaliere: $attivitaGiornaliere
raggio massimo: ${raggioKm.toInt()} km

### Profilo del viaggiatore:
- Tipologia: $tipologiaViaggiatore
- Età media: ${etaMedia.toInt()}
- Profilo aggiuntivo: $profilo

Formato richiesto:
{
  "giorno1": [
    {
      "titolo": "Check-in hotel",
      "descrizione": "Arrivo e sistemazione in hotel 3 stelle.",
      "orario": "15:00",
      "luogo": "Hotel Centrale",
      "categoria": "pernottamento",
      "costoStimato": 80.0
    },
    ...
  ],
  "giorno2": [
    {
      "titolo": "Passeggiata in centro",
      "descrizione": "Passeggiata rilassante nel centro storico.",
      "orario": "17:00",
      "luogo": "Centro città",
      "categoria": "attività",
      "costoStimato": 0.0
    },
    ...
  ],
  "giorno3": [
    {
      "titolo": "volo",
      "descrizione": "volo di ritorno",
      "orario": "20:00",
      "luogo": "aeroporto",
      "categoria": "trasporto",
      "costoStimato": 320.0
    }
    ...
  ]
}

Il totale dei costi stimati deve essere allineato al budget indicato.
Il JSON deve contenere da 1 a $attivitaGiornaliere attività per ciascun giorno.
Le attività devono rispettare il raggio massimo specificato (massimo ${raggioKm.toInt()} km dalla destinazione).
Il totale dei costi stimati deve essere in linea col budget specificato.
Le categorie valide sono: "trasporto", "attività", "pernottamento".

Regole:
- Restituisci solo JSON puro
- Evita caratteri speciali o virgolette non chiuse
- Nessun testo prima o dopo
- Non usare markdown

''';

try {
  print("🚀 Invio prompt a Gemini...");
  final response = await model.generateContent([
    Content.text(prompt),
  ]);

  final output = response.text;

  if (output == null || output.trim().isEmpty) {
    throw Exception('Gemini non ha generato nulla');
  }

  // ✅ Pulisce eventuali blocchi markdown
  final cleanedOutput = output
      .replaceAll('```json', '')
      .replaceAll('```', '')
      .trim();

  print('✅ Risposta Gemini pulita:\n$cleanedOutput');
  return cleanedOutput;
} catch (e) {
  print('❌ Errore durante la generazione: $e');
  rethrow;
}
  }
}
