import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../features/sync/presentation/sync_indicator_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showSearch;
  final ValueChanged<String>? onSearchChanged;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.showSearch = false,
    this.onSearchChanged,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (showSearch ? 60 : 0) + (bottom != null ? 48 : 0));

  @override
  Widget build(BuildContext context) {
    final effectiveActions = [
      ...?actions,
      const SyncIndicatorWidget(),
      const SizedBox(width: 8),
    ];

    return AppBar(
      title: Text(title),
      actions: effectiveActions,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: showSearch
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant.withAlpha(150),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
            )
          : (bottom as PreferredSizeWidget?),
    );
  }
}
