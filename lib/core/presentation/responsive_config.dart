import 'package:flutter/material.dart';

/// A single source of truth for all responsive layout breakpoints,
/// constraints, and grid delegates across different screen sizes.
class ResponsiveConfig {
  static const double maxWidthDesktop = 1200.0;
  
  /// A standard grid delegate for media items (Vault Dashboard)
  static SliverGridDelegate getVaultGridDelegate() {
    return const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 140, // Keeps items appropriately sized on large screens
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    );
  }

  /// A standard grid delegate for albums
  static SliverGridDelegate getAlbumGridDelegate() {
    return const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 280, // Prevents huge stretching on desktop
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
    );
  }

  /// Wraps a body widget with a maximum width to prevent infinite stretching on Windows/macOS/Linux.
  static Widget buildConstrainedBody({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidthDesktop),
        child: child,
      ),
    );
  }
}
