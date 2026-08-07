import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../features/vault/domain/vault_item_entity.dart';
import '../../theme/app_theme.dart';

class VaultCard extends StatefulWidget {
  final VaultItemEntity item;
  final Widget? thumbnail;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const VaultCard({
    super.key,
    required this.item,
    this.thumbnail,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<VaultCard> createState() => _VaultCardState();
}

class _VaultCardState extends State<VaultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
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
                      color: Colors.black.withAlpha(50),
                      blurRadius: 12,
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
                  child: Container(
                    color: AppTheme.surface,
                    child: widget.thumbnail ?? const Center(
                      child: Icon(
                        Icons.lock,
                        color: AppTheme.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      widget.item.type == 'video' ? Icons.videocam : Icons.image,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.item.originalName,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
