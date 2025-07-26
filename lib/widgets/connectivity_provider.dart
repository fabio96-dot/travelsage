import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) async* {
  await for (final results in Connectivity().onConnectivityChanged) {
    yield results.first;
  }
});

/// ✅ Provider booleano che indica se l'utente è online
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider).asData?.value;
  return status != null && status != ConnectivityResult.none;
});

/// ❌ Provider inverso per sapere se è offline
final isOfflineProvider = Provider<bool>((ref) => !ref.watch(isOnlineProvider));


