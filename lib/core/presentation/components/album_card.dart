import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../features/vault/state/vault_notifier.dart';
import '../../../features/vault/presentation/encrypted_grid_widget.dart';

class AlbumCard extends ConsumerStatefulWidget {
  final String title;
  final int itemCount;
  final bool isLocked;
  final int? coverItemId;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.title,
    required this.itemCount,
    this.isLocked = false,
    this.coverItemId,
    required this.onTap,
  });

  @override
  ConsumerState<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends ConsumerState<AlbumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(50),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppTheme.surface,
                        child: (widget.coverItemId != null) 
                            ? ref.watch(coverItemProvider(widget.coverItemId!)).when(
                                data: (item) => item != null ? EncryptedGridWidget(item: item) : _buildFallbackIcon(),
                                loading: () => _buildFallbackIcon(),
                                error: (_, __) => _buildFallbackIcon(),
                              )
                            : _buildFallbackIcon(),
                      ),
                      if (widget.isLocked)
                        Container(
                          color: Colors.black.withAlpha(150),
                          child: const Center(
                            child: Icon(Icons.lock_outline, color: Colors.white, size: 32),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.itemCount} items',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Icon(
      widget.isLocked ? Icons.lock : Icons.folder,
      color: widget.isLocked ? AppTheme.error.withAlpha(150) : AppTheme.primary.withAlpha(150),
      size: 48,
    );
  }
}
