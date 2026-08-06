import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../state/media_viewer_state.dart';

class ImageItemViewer extends ConsumerStatefulWidget {
  final VaultItemEntity item;

  const ImageItemViewer({super.key, required this.item});

  @override
  ConsumerState<ImageItemViewer> createState() => _ImageItemViewerState();
}

class _ImageItemViewerState extends ConsumerState<ImageItemViewer> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails!.localPosition;
    const double scale = 3.0; // Zoom factor
    final x = -position.dx * (scale - 1);
    final y = -position.dy * (scale - 1);
    
    Matrix4 endMatrix;
    if (_transformationController.value.isIdentity()) {
      endMatrix = Matrix4.identity()
        ..setTranslationRaw(x, y, 0.0)
        ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
    } else {
      endMatrix = Matrix4.identity();
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playbackSessionProvider(widget.item));

    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: sessionState.when(
            data: (session) {
              return Hero(
                tag: widget.item.id.toString(),
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
      ),
    );
  }

  Widget _buildSkeleton() {
    return Hero(
      tag: widget.item.id.toString(),
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
              Text('Decrypting\n${widget.item.originalName}...', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
