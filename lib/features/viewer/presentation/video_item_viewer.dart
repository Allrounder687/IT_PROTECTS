import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../vault/domain/vault_item_entity.dart';

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
    _initVideo();
  }
  
  Future<void> _initVideo() async {
    // In a real implementation, we would pass the decrypted bytes or secure local proxy URL to MediaKit.
    // For this skeleton, we just mock the video load.
    
    // final bytes = await ref.read(fullMediaProvider(widget.item.id).future);
    // player.open(Media.memory(bytes)); // media_kit supports in-memory playback in some platforms
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
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
  }
}
