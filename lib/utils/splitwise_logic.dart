import '../models/spesa.dart';

/// Calcola i debiti grezzi: chi deve quanto a chi, senza ottimizzazione.
Map<String, Map<String, double>> calcolaDebitiGrezzi(List<Spesa> spese) {
  final debiti = <String, Map<String, double>>{};

  for (var spesa in spese) {
    if (spesa.coinvolti.isEmpty || spesa.importo == 0) continue;

    final quota = spesa.importo / spesa.coinvolti.length;

    for (var coinvolto in spesa.coinvolti) {
      if (coinvolto == spesa.pagatore) continue;

      debiti.putIfAbsent(coinvolto, () => {});

      debiti[coinvolto]!.update(
        spesa.pagatore,
        (val) => double.parse((val + quota).toStringAsFixed(2)),
        ifAbsent: () => double.parse(quota.toStringAsFixed(2)),
      );
    }
  }

  return debiti;
}

/// Ottimizza i debiti calcolando solo le transazioni finali.
List<Map<String, dynamic>> calcolaDebitiOttimizzati(List<Spesa> spese) {
  final bilanci = <String, double>{};

  // Fase 1: calcolo dei bilanci netti (positivi = credito, negativi = debito)
  for (var spesa in spese) {
    final quota = spesa.importo / spesa.coinvolti.length;

    for (var coinvolto in spesa.coinvolti) {
      bilanci[coinvolto] = (bilanci[coinvolto] ?? 0) - quota;
    }

    bilanci[spesa.pagatore] = (bilanci[spesa.pagatore] ?? 0) + spesa.importo;
  }

  // Fase 2: separa debitori e creditori
  final creditori = <String, double>{};
  final debitori = <String, double>{};

  bilanci.forEach((nome, saldo) {
    if (saldo > 0) {
      creditori[nome] = saldo;
    } else if (saldo < 0) {
      debitori[nome] = -saldo;
    }
  });

  // Fase 3: risoluzione dei debiti
  final transazioni = <Map<String, dynamic>>[];

  final creditoriOrdinati = creditori.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final debitoriOrdinati = debitori.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  int i = 0, j = 0;

  while (i < debitoriOrdinati.length && j < creditoriOrdinati.length) {
    final debitore = debitoriOrdinati[i];
    final creditore = creditoriOrdinati[j];

    final somma = debitore.value < creditore.value
        ? debitore.value
        : creditore.value;

    transazioni.add({
      'from': debitore.key,
      'to': creditore.key,
      'amount': double.parse(somma.toStringAsFixed(2)),
    });

    debitoriOrdinati[i] = MapEntry(debitore.key, debitore.value - somma);
    creditoriOrdinati[j] = MapEntry(creditore.key, creditore.value - somma);

    if (debitoriOrdinati[i].value == 0) i++;
    if (creditoriOrdinati[j].value == 0) j++;
  }

  return transazioni;
}
