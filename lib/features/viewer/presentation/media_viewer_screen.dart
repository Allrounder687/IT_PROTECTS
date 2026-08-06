import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../vault/state/vault_notifier.dart';
import 'image_item_viewer.dart';
import 'video_item_viewer.dart';
import 'doc_item_viewer.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MediaViewerScreen({super.key, required this.initialIndex});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late PageController _pageController;
  bool _showHud = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleHud() {
    setState(() {
      _showHud = !_showHud;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaItemsState = ref.watch(vaultListProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Immersive viewer
      body: mediaItemsState.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No items'));

          return Stack(
            children: [
              GestureDetector(
                onTap: _toggleHud,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    
                    if (item.originalName.endsWith('.mp4') || item.originalName.endsWith('.mov')) {
                      return VideoItemViewer(item: item, showHud: _showHud);
                    } else if (item.originalName.endsWith('.pdf')) {
                      return DocItemViewer(item: item);
                    } else {
                      return ImageItemViewer(item: item);
                    }
                  },
                ),
              ),

              // HUD Overlay - Top Bar
              if (_showHud)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: Text(
                              items[_currentIndex].originalName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.white),
                            onPressed: () {
                              // Show EXIF / Crypto info bottom sheet
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 200.ms).slideY(begin: -1, end: 0),
                ),
                
              // Additional Bottom Bar could go here (e.g. Delete, Share) if not video
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
