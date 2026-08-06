import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../state/media_viewer_state.dart';

class DocItemViewer extends ConsumerWidget {
  final VaultItemEntity item;

  const DocItemViewer({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullMedia = ref.watch(fullMediaProvider(item.id.toString()));

    return Center(
      child: fullMedia.when(
        data: (bytes) {
          // If we had valid PDF bytes, we would return:
          // return SfPdfViewer.memory(bytes);
          
          return Container(
             color: Colors.white,
             child: const Center(
               child: Text('PDF Decrypted and Rendered Here', style: TextStyle(color: Colors.black)),
             ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => Text('Error loading doc: $e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
