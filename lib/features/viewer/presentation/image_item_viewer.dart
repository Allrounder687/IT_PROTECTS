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
            return Hero(
              tag: item.id.toString(),
              child: Image.file(
                session.file,
                fit: BoxFit.contain,
              ),
            );
          },
          loading: () => _buildSkeleton(),
          error: (e, st) => Center(child: Text('Error decrypting image: $e', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Hero(
      tag: item.id.toString(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF334155), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white54),
              const SizedBox(height: 16),
              Text('Decrypting\n${item.originalName}...', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
