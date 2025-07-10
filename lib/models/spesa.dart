class Spesa {
  String descrizione;
  double importo;
  String pagatore;
  List<String> coinvolti;
  DateTime data;

  Spesa({
    required this.descrizione,
    required this.importo,
    required this.pagatore,
    required this.coinvolti,
    required this.data,
  });
}
