// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

    final ext = file.extension?.toLowerCase() ?? 'jpg';
    final isGif = ext == 'gif';

    // Compress / resize before upload (skip for GIFs — keep as-is)
    final uploadBytes = isGif ? rawBytes : await _compress(rawBytes, preset);
    final contentType = isGif ? 'image/gif' : 'image/jpeg';
    final uploadExt = isGif ? 'gif' : 'jpg';

    final uniqueId = const Uuid().v4();
    final ref = _storage.ref('$basePath/$uniqueId.$uploadExt');
    await ref.putData(uploadBytes, SettableMetadata(contentType: contentType));
    return await ref.getDownloadURL();
  }

  /// Resizes and re-encodes the image as JPEG using the browser Canvas API.
  /// Falls back to the original bytes on any error.
  static Future<Uint8List> _compress(
    Uint8List bytes,
    ImageCompressPreset preset,
  ) async {
    try {
      // Create a blob URL so the browser can decode any supported format
      final blob = html.Blob([bytes]);
      final objectUrl = html.Url.createObjectUrlFromBlob(blob);

      final imgEl = html.ImageElement();
      final loadCompleter = Completer<void>();
      imgEl.onLoad.first.then((_) => loadCompleter.complete());
      imgEl.onError.first.then(
        (_) => loadCompleter.completeError('Image load failed'),
      );
      imgEl.src = objectUrl;

      await loadCompleter.future;
      html.Url.revokeObjectUrl(objectUrl);

      int srcW = imgEl.naturalWidth ?? 0;
      int srcH = imgEl.naturalHeight ?? 0;
      if (srcW == 0 || srcH == 0) return bytes;

      // Calculate target dimensions while preserving aspect ratio
      int dstW = srcW;
      int dstH = srcH;
      if (srcW > preset.maxDimension || srcH > preset.maxDimension) {
        if (srcW >= srcH) {
          dstW = preset.maxDimension;
          dstH = (srcH * preset.maxDimension / srcW).round();
        } else {
          dstH = preset.maxDimension;
          dstW = (srcW * preset.maxDimension / srcH).round();
        }
      }

      final canvas = html.CanvasElement(width: dstW, height: dstH);
      canvas.context2D.drawImageScaled(imgEl, 0, 0, dstW, dstH);

      // toDataUrl quality is 0.0–1.0
      final dataUrl = canvas.toDataUrl(
        'image/jpeg',
        preset.quality / 100.0,
      );

      // Strip the "data:image/jpeg;base64," prefix
      final base64Part = dataUrl.split(',').last;
      final compressed = base64Decode(base64Part);

      // Safety: if encoding made it larger, return the original
      return compressed.length < bytes.length
          ? Uint8List.fromList(compressed)
          : bytes;
    } catch (_) {
      // Any failure (unsupported format, browser quirk) → upload original
      return bytes;
    }
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
