import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/storage_provider.dart';

final activeCloudProvider = NotifierProvider<ActiveCloudProviderNotifier, StorageProvider?>(ActiveCloudProviderNotifier.new);

class ActiveCloudProviderNotifier extends Notifier<StorageProvider?> {
  @override
  StorageProvider? build() {
    // Initial state is no provider active.
    // In a real app, this would check SharedPreferences for the last used provider
    // and initialize it if tokens are still valid.
    return null;
  }

  void setProvider(StorageProvider provider) {
    state = provider;
  }
  
  void clearProvider() {
    state = null;
  }
}
