import 'dart:io';
import 'package:flutter/material.dart';

/// A single source of truth for all responsive layout breakpoints,
/// constraints, and grid delegates across different screen sizes.
class ResponsiveConfig {
  static const double maxWidthDesktop = 1200.0;
  
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  
  /// A standard grid delegate for media items (Vault Dashboard)
  static SliverGridDelegate getVaultGridDelegate() {
    final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    if (isDesktop) {
      return const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      );
    }
    
    // Restore old android layout
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    );
  }

  /// A standard grid delegate for albums
  static SliverGridDelegate getAlbumGridDelegate() {
    final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    if (isDesktop) {
      return const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.9,
      );
    }
    
    // Fixed layout for mobile
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.9,
    );
  }

  /// Wraps a body widget with a maximum width to prevent infinite stretching on Windows/macOS/Linux.
  /// Use this for forms, settings screens, and text-heavy pages.
  static Widget buildConstrainedBody({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidthDesktop),
        child: child,
      ),
    );
  }

  /// Wraps a body widget without a maximum width constraint, allowing it to fluidly expand.
  /// Use this for GridViews (e.g. Vault Dashboard, Albums) so they can utilize large screens.
  static Widget buildFluidBody({required Widget child}) {
    return child;
  }
}
