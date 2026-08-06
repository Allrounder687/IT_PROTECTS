import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../state/media_viewer_state.dart';

class VideoItemViewer extends ConsumerStatefulWidget {
  final VaultItemEntity item;
  final bool showHud;

  const VideoItemViewer({super.key, required this.item, required this.showHud});

  @override
  ConsumerState<VideoItemViewer> createState() => _VideoItemViewerState();
}

class _VideoItemViewerState extends ConsumerState<VideoItemViewer> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playbackSessionProvider(widget.item));

    return sessionState.when(
      data: (session) {
        if (!_isInitialized) {
          player.open(Media(session.file.path));
          _isInitialized = true;
        }

        return Stack(
          children: [
            Center(
              child: Video(controller: controller),
            ),
            // Mock Video Scrubber when HUD is visible
            if (widget.showHud)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () => player.play(),
                      ),
                      const Expanded(
                        child: Slider(
                          value: 0,
                          onChanged: null,
                        ),
                      ),
                      const Text('0:00 / 0:00', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading video: $e', style: const TextStyle(color: Colors.red))),
    );
  }
}
