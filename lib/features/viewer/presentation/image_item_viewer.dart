import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../state/media_viewer_state.dart';

class ImageItemViewer extends ConsumerWidget {
  final VaultItemEntity item;

  const ImageItemViewer({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(playbackSessionProvider(item));

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Center(
        child: sessionState.when(
          data: (session) {
            // Mock: in reality, bytes would be passed to Image.file(session.file)
            // We'll show a beautifully styled placeholder for the skeleton
            return Hero(
              tag: item.id.toString(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF334155), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, size: 80, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text('Secure Image\n${item.id}.enc', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, st) => Text('Error decrypting image: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
