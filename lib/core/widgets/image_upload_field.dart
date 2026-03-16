import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import '../theme/app_theme.dart';
import 'smart_network_image.dart';

export '../services/image_upload_service.dart' show ImageCompressPreset;

/// A reusable image upload widget that replaces plain URL text fields.
///
/// - [isCircular] = true  → compact circular avatar (for characters/creatures)
/// - [isCircular] = false → full-width rectangular card (for maps/locations)
///
/// [storagePath] is the Firebase Storage folder path, e.g. 'images/uid/creatures'.
/// [onChanged] is called with the new URL after upload, or null when removed.
class ImageUploadField extends StatefulWidget {
  final String? currentImageUrl;
  final String storagePath;
  final ValueChanged<String?> onChanged;
  final bool isCircular;
  final double height;
  final String label;
  final IconData placeholderIcon;
  final ImageCompressPreset preset;

  const ImageUploadField({
    super.key,
    this.currentImageUrl,
    required this.storagePath,
    required this.onChanged,
    this.isCircular = false,
    this.height = 180,
    this.label = 'Imagem',
    this.placeholderIcon = Icons.add_photo_alternate_outlined,
    this.preset = ImageCompressPreset.location,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  bool _isUploading = false;
  String? _localUrl;

  String? get _effectiveUrl => _localUrl ?? widget.currentImageUrl;

  Future<void> _pickAndUpload() async {
    setState(() => _isUploading = true);
    try {
      final url = await ImageUploadService.pickAndUpload(
        widget.storagePath,
        preset: widget.preset,
      );
      if (url != null && mounted) {
        setState(() => _localUrl = url);
        widget.onChanged(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar imagem: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage() {
    setState(() => _localUrl = null);
    widget.onChanged(null);
  }

  // ─── Rectangular (maps / locations) ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return widget.isCircular ? _buildCircular() : _buildRectangular();
  }

  Widget _buildRectangular() {
    final hasImage = (_effectiveUrl ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUpload,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(
                color: hasImage
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : AppTheme.textMuted.withValues(alpha: 0.35),
                width: 1.5,
              ),
              color: hasImage ? null : AppTheme.surfaceLight.withValues(alpha: 0.4),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isUploading
                ? const Center(child: CircularProgressIndicator())
                : hasImage
                    ? _buildPreview()
                    : _buildEmptyState(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        SmartNetworkImage(imageUrl: _effectiveUrl!, fit: BoxFit.cover),
        // Overlay gradient for button visibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Row(
            children: [
              _overlayButton(
                icon: Icons.edit,
                label: 'Trocar',
                onTap: _pickAndUpload,
              ),
              const SizedBox(width: 6),
              _overlayButton(
                icon: Icons.delete_outline,
                label: 'Remover',
                onTap: _removeImage,
                color: AppTheme.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.placeholderIcon,
          size: 44,
          color: AppTheme.textMuted.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 10),
        Text(
          'Clique para adicionar imagem',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG, WEBP',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textMuted.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ─── Circular (avatars) ──────────────────────────────────────────────────

  Widget _buildCircular() {
    final hasImage = (_effectiveUrl ?? '').isNotEmpty;
    const double size = 84;

    return Tooltip(
      message: 'Clique para alterar imagem',
      child: GestureDetector(
        onTap: _isUploading ? null : _pickAndUpload,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
              child: _isUploading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : hasImage
                      ? ClipOval(
                          child: SmartNetworkImage(
                            imageUrl: _effectiveUrl!,
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          widget.placeholderIcon,
                          color: AppTheme.primary.withValues(alpha: 0.7),
                          size: 38,
                        ),
            ),
            // Camera badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
              ),
            ),
            // Remove button (only when image exists)
            if (hasImage && !_isUploading)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 2),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
