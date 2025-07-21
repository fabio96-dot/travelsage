import 'package:flutter/material.dart';
import '../../models/viaggio.dart';
import 'package:intl/intl.dart';

class DiaryCard extends StatelessWidget {
  final Viaggio viaggio;

  const DiaryCard({super.key, required this.viaggio});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d MMM yyyy', 'it_IT');
    final periodo = '${formatter.format(viaggio.dataInizio)} - ${formatter.format(viaggio.dataFine)}';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
  
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viaggio.destinazione,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      periodo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.emoji_flags_outlined, color: Colors.indigo)
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        const SizedBox(height: 8),
      ],
    );
  }
}
