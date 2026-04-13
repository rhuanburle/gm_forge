// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

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

  /// Opens a file picker, compresses the image, and uploads to Firebase Storage
  /// under [basePath].
  ///
  /// Returns the public download URL, or null if the user cancelled.
  static Future<String?> pickAndUpload(
    String basePath, {
    ImageCompressPreset preset = ImageCompressPreset.location,
  }) async {
    // Use dart:html directly — avoids file_picker late-field issues in release
    final rawBytes = await _pickImageBytes();
    if (rawBytes == null) return null;

    // Detect format from magic bytes
    final ext = _detectExtension(rawBytes);
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

  /// Opens a native file-input dialog and returns the raw bytes of the selected
  /// image, or null if the user cancelled.
  static Future<Uint8List?> _pickImageBytes() async {
    final completer = Completer<Uint8List?>();

    final input = html.FileUploadInputElement()..accept = 'image/*';

    // Append hidden to body so it works in all browsers
    html.document.body!.append(input);

    input.onChange.first.then((_) {
      input.remove();
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.first.then((_) {
        final result = reader.result;
        if (!completer.isCompleted) {
          completer.complete(result is Uint8List ? result : null);
        }
      });
      reader.readAsArrayBuffer(files[0]);
    });

    // Detect cancel: window regains focus but input didn't fire change
    late html.EventListener focusListener;
    focusListener = (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!completer.isCompleted) {
        input.remove();
        completer.complete(null);
      }
      html.window.removeEventListener('focus', focusListener);
    };
    html.window.addEventListener('focus', focusListener);

    input.click();
    return completer.future;
  }

  /// Detects the image format from the first bytes (magic numbers).
  static String _detectExtension(Uint8List bytes) {
    if (bytes.length >= 6) {
      // GIF87a / GIF89a
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'gif';
      }
      // PNG
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) {
        return 'png';
      }
      // JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';
      // WebP
      if (bytes[0] == 0x52 && bytes[1] == 0x49 &&
          bytes[8] == 0x57 && bytes[9] == 0x45) return 'webp';
    }
    return 'jpg';
  }

  /// Resizes and re-encodes the image as JPEG using the browser Canvas API.
  /// Falls back to the original bytes on any error.
  static Future<Uint8List> _compress(
    Uint8List bytes,
    ImageCompressPreset preset,
  ) async {
    try {
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

      final dataUrl = canvas.toDataUrl('image/jpeg', preset.quality / 100.0);
      final base64Part = dataUrl.split(',').last;
      final compressed = base64Decode(base64Part);

      return compressed.length < bytes.length
          ? Uint8List.fromList(compressed)
          : bytes;
    } catch (_) {
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
