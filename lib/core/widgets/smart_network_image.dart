import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SmartNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _buildPlaceholder();

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stack) => _buildPlaceholder(),
      );
    }

    // Use CachedNetworkImage for persistent disk cache (not available on web,
    // but the package gracefully falls back to a memory-only cache there).
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildLoading(),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
      // Limit decoded size to save memory on large images
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceLight,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: AppTheme.surfaceLight,
          child: const Icon(Icons.image_not_supported, color: AppTheme.textMuted),
        );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceLight,
      padding: const EdgeInsets.all(8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: AppTheme.error, size: 24),
            if (kIsWeb) ...[
              const SizedBox(height: 8),
              const Text(
                'Erro ao carregar imagem',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse(imageUrl)),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Abrir imagem', style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Text(
                'Erro ao carregar',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
