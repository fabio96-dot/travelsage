import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper<T> {
  final String boxName;

  HiveHelper(this.boxName);

  Future<Box<T>> openBox({int? adapterTypeId, TypeAdapter<T>? adapter}) async {
    if (adapterTypeId != null && adapter != null && !Hive.isAdapterRegistered(adapterTypeId)) {
      Hive.registerAdapter(adapter);
    }

    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<T>(boxName);
    }
    return Hive.box<T>(boxName);
  }

  Future<List<T>> getAll() async {
    final box = await openBox();
    return box.values.toList();
  }

  Future<void> save(String key, T item) async {
    final box = await openBox();
    await box.put(key, item);
  }

  Future<void> delete(String key) async {
    final box = await openBox();
    await box.delete(key);
  }

  Future<void> clearAll() async {
    final box = await openBox();
    await box.clear();
  }
}
