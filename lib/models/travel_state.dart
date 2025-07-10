class TravelState {
  static List<Map<String, dynamic>> _viaggi = [];
  
  static void aggiungiViaggio(Map<String, dynamic> viaggio) {
    _viaggi.add(viaggio);
  }
  
  static List<Map<String, dynamic>> get viaggiDaArchiviare => _viaggi;
}