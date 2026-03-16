import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

/// Controls compression settings per image context.
enum ImageCompressPreset {
  /// Dungeon maps and adventure covers — large, detail matters.
  /// Max 1920×1920 px · JPEG 85%  → ~200–400 KB
  map(maxDimension: 1920, quality: 85),

  /// Location / room images — medium detail.
  /// Max 1280×1280 px · JPEG 82%  → ~100–250 KB
  location(maxDimension: 1280, quality: 82),

  /// Character / creature avatars — small, face-level detail.
  /// Max 600×600 px · JPEG 80%  → ~30–80 KB
  avatar(maxDimension: 600, quality: 80);

  const ImageCompressPreset({
    required this.maxDimension,
    required this.quality,
  });

  final int maxDimension;

  /// JPEG quality 0–100.
  final int quality;
}

class ImageUploadService {
  static final _storage = FirebaseStorage.instance;

  /// Picks an image, compresses it according to [preset], and uploads to
  /// Firebase Storage under [basePath].
  ///
  /// Returns the public download URL, or null if the user cancelled.
  static Future<String?> pickAndUpload(
    String basePath, {
    ImageCompressPreset preset = ImageCompressPreset.location,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final rawBytes = file.bytes;
    if (rawBytes == null) return null;

    // Compress / resize before upload
    final compressed = await _compress(rawBytes, preset);

    // Always store as JPEG after compression (except GIF — keep as-is)
    final ext = file.extension?.toLowerCase() ?? 'jpg';
    final isGif = ext == 'gif';
    final uploadBytes = isGif ? rawBytes : compressed;
    final contentType = isGif ? 'image/gif' : 'image/jpeg';
    final uploadExt = isGif ? 'gif' : 'jpg';

    final uniqueId = const Uuid().v4();
    final ref = _storage.ref('$basePath/$uniqueId.$uploadExt');
    await ref.putData(uploadBytes, SettableMetadata(contentType: contentType));
    return await ref.getDownloadURL();
  }

  /// Decodes, resizes (if needed) and re-encodes as JPEG.
  static Future<Uint8List> _compress(
    Uint8List bytes,
    ImageCompressPreset preset,
  ) async {
    // Decode — returns null if format is unsupported
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes; // fallback: upload original

    final originalSize = bytes.length;

    // Resize only if either dimension exceeds the limit
    img.Image resized = decoded;
    if (decoded.width > preset.maxDimension ||
        decoded.height > preset.maxDimension) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? preset.maxDimension : null,
        height: decoded.height > decoded.width ? preset.maxDimension : null,
        interpolation: img.Interpolation.linear,
      );
    }

    final encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: preset.quality),
    );

    // Safety: if encoding somehow made it larger, return the original
    return encoded.length < originalSize ? encoded : bytes;
  }

  /// Deletes an image from Firebase Storage by its download URL.
  /// Silently ignores errors (file may already be deleted).
  static Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
