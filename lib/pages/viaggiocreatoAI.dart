import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:travel_sage/models/viaggio.dart';
import 'package:travel_sage/pages/viaggio_dettaglio_page.dart';

class ViaggioCreatoPage extends StatefulWidget {
  final Viaggio viaggio;

  const ViaggioCreatoPage({super.key, required this.viaggio});

  @override
  State<ViaggioCreatoPage> createState() => _ViaggioCreatoPageState();
}

class _ViaggioCreatoPageState extends State<ViaggioCreatoPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; // <--- Controllo essenziale
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ViaggioDettaglioPage(
            viaggio: widget.viaggio,
            index: -1,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/splash_travel.json',
                width: 400,
                repeat: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Viaggio creato con successo! 🎉',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_contieneAttivitaGenerataDaIA(widget.viaggio))
                Text(
                  '✍️ Itinerario creato con intelligenza artificiale',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              Text(
                'Preparati alla partenza con TravelSage 🚀',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _contieneAttivitaGenerataDaIA(Viaggio viaggio) {
    for (final giorno in viaggio.itinerario.values) {
      if (giorno.any((a) => a.generataDaIA)) return true;
    }
    return false;
  }
}
