import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../responsive_config.dart';
import '../../theme/app_theme.dart';

class SkeletonGrid extends StatelessWidget {
  final bool isAlbum;

  const SkeletonGrid({super.key, this.isAlbum = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: isAlbum 
          ? ResponsiveConfig.getAlbumGridDelegate() 
          : ResponsiveConfig.getVaultGridDelegate(),
      itemCount: 12, // Arbitrary number of skeletons to fill the screen
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        )
        .animate()
        .fade(begin: 0.3, end: 0.7, duration: 800.ms);
      },
    );
  }
}
