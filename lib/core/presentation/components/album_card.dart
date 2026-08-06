import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class AlbumCard extends StatefulWidget {
  final String title;
  final int itemCount;
  final bool isLocked;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.title,
    required this.itemCount,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
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
                        child: Icon(
                          widget.isLocked ? Icons.lock : Icons.folder,
                          color: widget.isLocked ? AppTheme.error.withAlpha(150) : AppTheme.primary.withAlpha(150),
                          size: 48,
                        ),
                      ),
                      if (widget.isLocked)
                        Container(
                          color: Colors.black.withAlpha(100),
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
}
