import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../../features/auth/state/auth_notifier.dart';

class DesktopSidebar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const DesktopSidebar({super.key, required this.navigationShell});

  @override
  ConsumerState<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<DesktopSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 88 : 260,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Area
              SizedBox(
                height: 104,
                child: Stack(
                  children: [
                    // Expanded content
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isCollapsed ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isCollapsed,
                        child: ExcludeSemantics(
                          excluding: _isCollapsed,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Container(
                              width: 260,
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                              child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.shield, size: 24, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'IT PROTECTS',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                    overflow: TextOverflow.clip,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.menu_open, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                      _isCollapsed = true;
                                    });
                                  },
                                  tooltip: 'Collapse Sidebar',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Collapsed content
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isCollapsed ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_isCollapsed,
                        child: ExcludeSemantics(
                          excluding: !_isCollapsed,
                          child: Container(
                            width: 88,
                            padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
                            alignment: Alignment.center,
                            child: IconButton(
                              icon: const Icon(Icons.menu, color: AppTheme.textSecondary),
                              onPressed: () {
                                setState(() {
                                  _isCollapsed = false;
                                });
                              },
                              tooltip: 'Expand Sidebar',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _SidebarItem(
                      icon: Icons.shield_outlined,
                      selectedIcon: Icons.shield,
                      label: 'Private Vault',
                      isSelected: widget.navigationShell.currentIndex == 0,
                      isCollapsed: _isCollapsed,
                      onTap: () => _navigate(0),
                    ),
                    const SizedBox(height: 8),
                    _SidebarItem(
                      icon: Icons.photo_album_outlined,
                      selectedIcon: Icons.photo_album,
                      label: 'Albums',
                      isSelected: widget.navigationShell.currentIndex == 1,
                      isCollapsed: _isCollapsed,
                      onTap: () => _navigate(1),
                    ),
                    const SizedBox(height: 8),
                    _SidebarItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      isSelected: widget.navigationShell.currentIndex == 2,
                      isCollapsed: _isCollapsed,
                      onTap: () => _navigate(2),
                    ),
                  ],
                ),
              ),
              
              // Bottom Action (Lock)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: _SidebarItem(
                  icon: Icons.lock_outline,
                  selectedIcon: Icons.lock,
                  label: 'Lock Vault',
                  isSelected: false,
                  isCollapsed: _isCollapsed,
                  isDestructive: true,
                  onTap: () => ref.read(authNotifierProvider.notifier).lockVault(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigate(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final defaultColor = widget.isDestructive ? AppTheme.error : AppTheme.textSecondary;
    final activeColor = widget.isDestructive ? AppTheme.error : AppTheme.primary;
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
      color: widget.isSelected ? Colors.white : (widget.isDestructive ? AppTheme.error : AppTheme.textPrimary),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.isCollapsed ? widget.label : '',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 12 : 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: widget.isSelected && !widget.isDestructive
                  ? AppTheme.primaryGradient
                  : null,
              color: widget.isSelected && widget.isDestructive
                  ? AppTheme.error.withValues(alpha: 0.2)
                  : (_isHovering ? AppTheme.surfaceVariant.withValues(alpha: 0.5) : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  widget.isSelected ? widget.selectedIcon : widget.icon,
                  color: widget.isSelected ? Colors.white : (_isHovering ? activeColor : defaultColor),
                  size: 24,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(child: Text(widget.label, style: textStyle, overflow: TextOverflow.clip, maxLines: 1, softWrap: false)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
