import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../state/media_viewer_state.dart';

class VideoItemViewer extends ConsumerStatefulWidget {
  final VaultItemEntity item;
  final bool showHud;
  final bool isSafeSend;

  const VideoItemViewer({
    super.key, 
    required this.item, 
    required this.showHud,
    this.isSafeSend = false,
  });

  @override
  ConsumerState<VideoItemViewer> createState() => _VideoItemViewerState();
}

class _VideoItemViewerState extends ConsumerState<VideoItemViewer> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  bool _isInitialized = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      player.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '${d.inMinutes}:$seconds';
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
            
            // Safe Send Badge
            if (widget.isSafeSend && widget.showHud)
              Positioned(
                top: 80, // below main app bar
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Safe Send: Sent to user@example.com (visible for 14:59)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().slideY(begin: -0.5, end: 0),
              ),

            // Video Controls HUD
            if (widget.showHud)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100, // accommodate safe send bottom bar if needed, but let's keep it 100
                  padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StreamBuilder<bool>(
                        stream: player.stream.playing,
                        builder: (context, snapshot) {
                          final playing = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                            onPressed: () {
                              if (playing) {
                                player.pause();
                              } else {
                                player.play();
                              }
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                        onPressed: _toggleMute,
                      ),
                      Expanded(
                        child: StreamBuilder<Duration>(
                          stream: player.stream.position,
                          builder: (context, positionSnapshot) {
                            final position = positionSnapshot.data ?? Duration.zero;
                            
                            return StreamBuilder<Duration>(
                              stream: player.stream.duration,
                              builder: (context, durationSnapshot) {
                                final duration = durationSnapshot.data ?? Duration.zero;
                                final max = duration.inMilliseconds.toDouble();
                                final val = position.inMilliseconds.toDouble().clamp(0.0, max);
                                
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: max > 0 ? val : 0.0,
                                        min: 0.0,
                                        max: max > 0 ? max : 1.0,
                                        onChanged: (v) {
                                          player.seek(Duration(milliseconds: v.toInt()));
                                        },
                                      ),
                                    ),
                                    Text(
                                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                );
                              }
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => _buildSkeleton(),
      error: (e, st) => Center(child: Text('Error loading video: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildSkeleton() {
    return Container(
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
            Text('Decrypting\n${widget.item.originalName}...', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
