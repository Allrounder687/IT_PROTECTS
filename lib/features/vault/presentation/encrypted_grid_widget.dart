import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewer/state/viewer_notifier.dart';
import '../domain/vault_item_entity.dart';

class EncryptedGridWidget extends ConsumerWidget {
  final VaultItemEntity item;
  final BoxFit fit;

  const EncryptedGridWidget({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(decryptedItemProvider(item));

    return imageState.when(
      data: (bytes) => Image.memory(bytes, fit: fit),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
}
