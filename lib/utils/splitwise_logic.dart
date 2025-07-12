import '../models/spesa.dart';
import 'dart:math';

class SplitwiseLogic {
  static Map<String, double> calculateNetBalances(List<Spesa> spese, List<String> partecipanti) {
    final balances = <String, double>{};
    
    // Inizializza tutti i partecipanti
    for (final p in partecipanti) {
      balances[p] = 0.0;
    }

    // Calcola i saldi netti
    for (final spesa in spese) {
      final quota = spesa.importo / spesa.coinvolti.length;
      
      // Aggiungi l'importo totale al pagatore
      balances[spesa.pagatore] = balances[spesa.pagatore]! + spesa.importo;
      
      // Sottrai la quota a ciascun coinvolto
      for (final coinvolto in spesa.coinvolti) {
        balances[coinvolto] = balances[coinvolto]! - quota;
      }
    }

    return balances;
  }

  static List<Map<String, dynamic>> calculateOptimizedTransactions(List<Spesa> spese, List<String> partecipanti) {
    final balances = calculateNetBalances(spese, partecipanti);
    final transactions = <Map<String, dynamic>>[];
    
    // Converti i saldi in liste ordinate
    final creditors = balances.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final debtors = balances.entries
        .where((e) => e.value < 0)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    int i = 0, j = 0;
    
    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];
      
      final amount = min(-debtor.value, creditor.value);
      final roundedAmount = double.parse(amount.toStringAsFixed(2));
      
      if (roundedAmount > 0.01) { // Ignora transazioni minime
        transactions.add({
          'from': debtor.key,
          'to': creditor.key,
          'amount': roundedAmount,
        });
      }
      
      // Aggiorna i saldi
      debtors[i] = MapEntry(debtor.key, debtor.value + amount);
      creditors[j] = MapEntry(creditor.key, creditor.value - amount);
      
      if (debtors[i].value.abs() < 0.01) i++;
      if (creditors[j].value < 0.01) j++;
    }
    
    return transactions;
  }
}
