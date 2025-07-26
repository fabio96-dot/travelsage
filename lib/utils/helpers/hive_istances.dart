import 'package:hive_flutter/hive_flutter.dart';
import '../viaggio_type_adapter.dart'; // 👈 Assicurati di importare l'adapter generato
import '../../models/user_profile.dart';
import 'hive_boxes.dart';
import 'hive_helper.dart';
import '../../models/post_viaggio.dart';

Future<void> setupHive() async {
  await Hive.initFlutter();

  // 🔐 Registrazione adapter
  Hive.registerAdapter(UserProfileAdapter());      // typeId: 3
  Hive.registerAdapter(HiveAttivitaAdapter());     // typeId: 1
  Hive.registerAdapter(HiveViaggioAdapter());      // typeId: 2

  // 📦 Apertura box utente come dinamico
  final boxUtenteRaw = await Hive.openBox(boxUtente);

  // 🧹 Rimuove elementi non validi
  for (var key in boxUtenteRaw.keys) {
    final value = boxUtenteRaw.get(key);
    if (value is! UserProfile) {
      print('! Rimosso valore non valido da user_profile (chiave: $key)');
      await boxUtenteRaw.delete(key);
    }
  }

  // ❗ Chiudi il box prima di riaprirlo come tipizzato
  await boxUtenteRaw.close();

  // ✅ Ora lo riapriamo come tipizzato
  await Hive.openBox<UserProfile>(boxUtente);
  await Hive.openBox<HiveViaggio>(boxViaggi);
  await Hive.openBox<HiveAttivita>(boxAttivita);
}


final viaggiHelper = HiveHelper<HiveViaggio>(boxViaggi);
final attivitaHelper = HiveHelper<HiveAttivita>(boxAttivita);
final postHelper = HiveHelper<PostViaggio>(boxPostViaggi);
final utenteHelper = HiveHelper<UserProfile>(boxUtente);

