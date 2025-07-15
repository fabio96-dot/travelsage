import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class GeminiApi {
  final String apiKey;

  GeminiApi(this.apiKey);

  Future<String> generaItinerario({
    required String destinazione,
    required DateTime dataInizio,
    required DateTime dataFine,
    required String budget,
    required List<String> interessi,
  }) async {
    // Validazione input
    if (dataFine.isBefore(dataInizio)) {
      throw ArgumentError('La data finale non può essere precedente alla data iniziale');
    }

    final giorniViaggio = dataFine.difference(dataInizio).inDays + 1;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    final prompt = '''
Genera un itinerario di viaggio in STRETTO FORMATO JSON per $destinazione.
Periodo: ${dateFormatter.format(dataInizio)} - ${dateFormatter.format(dataFine)} ($giorniViaggio giorni)
Budget: $budget €
Interessi: ${interessi.join(', ')}

Formato richiesto ESATTO:
{
  "giorno1": [
    {
      "titolo": "Colazione",
      "descrizione": "...",
      "orario": "08:30",
      "luogo": "...",
      "durata": "1 ora",
      "costo": "€10"
    },
    ...
  ]
}''';

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/text-bison-001:generateText?key=$apiKey',
      );

      final headers = {
        'Content-Type': 'application/json',
      };

      // Configurazione corretta per text-bison-001
      final body = jsonEncode({
        'prompt': {
          'text': prompt
        },
        'temperature': 0.7,
        'maxOutputTokens': 2000,
        'topP': 0.9,
        // Safety settings supportati da text-bison-001:
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DEROGATORY',
            'threshold': 'BLOCK_LOW_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_TOXICITY',
            'threshold': 'BLOCK_LOW_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_VIOLENCE',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUAL',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_MEDICAL',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['candidates']?[0]?['output'] ?? '';
        
        if (result.isEmpty) {
          throw Exception('Nessun contenuto generato');
        }
        
        return result;
      } else {
        throw _handleApiError(response);
      }
    } on http.ClientException catch (e) {
      throw Exception('Errore di connessione: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Errore nel formato della risposta: $e');
    } catch (e) {
      throw Exception('Errore sconosciuto: $e');
    }
  }

  Exception _handleApiError(http.Response response) {
    final statusCode = response.statusCode;
    try {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?['message'] ?? response.body;
      return Exception('Errore API (${errorBody['error']?['code'] ?? statusCode}): $errorMessage');
    } catch (_) {
      return Exception('Errore API (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<String>> listAvailableModels() async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
    );
    
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['models'] as List)
          .map((m) => m['name'] as String)
          .toList();
    }
    throw Exception('Failed to fetch models: ${response.statusCode}');
  }
}
