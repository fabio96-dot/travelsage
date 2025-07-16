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
            maxOutputTokens: 2000,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          ],
        );

  Future<String> generaItinerario({
    required String destinazione,
    required DateTime dataInizio,
    required DateTime dataFine,
    required String budget,
    required List<String> interessi,
  }) async {
    if (dataFine.isBefore(dataInizio)) {
      throw ArgumentError('La data finale non può essere prima di quella iniziale');
    }

    final giorni = dataFine.difference(dataInizio).inDays + 1;
    final dateFormatter = DateFormat('dd/MM/yyyy');

final prompt = '''
Genera solo un oggetto JSON valido per questo viaggio. Non includere spiegazioni o testo aggiuntivo.

Viaggio a: $destinazione
Date: ${dateFormatter.format(dataInizio)} - ${dateFormatter.format(dataFine)} ($giorni giorni)
Budget: $budget €
Interessi: ${interessi.join(', ')}

Formato richiesto:
{
  "giorno1": [
    {
      "titolo": "Colazione",
      "descrizione": "Colazione tipica locale",
      "orario": "08:30",
      "luogo": "Centro città"
    },
    ...
  ],
  "giorno2": [...]
}

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
