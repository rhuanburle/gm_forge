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

  /// Opens a file picker and returns the raw image bytes, or null if cancelled.
  /// Does NOT upload — call [uploadBytes] afterwards to compress and store.
  static Future<Uint8List?> pickImageBytes() async {
    final completer = Completer<Uint8List?>();

    final input = html.FileUploadInputElement()..accept = 'image/*';
    // Must be in DOM for all browsers to fire the change event
    input.style.display = 'none';
    html.document.body!.append(input);

    input.onChange.first.then((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        _cleanup(input, completer, null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.first.then((_) {
        final result = reader.result;
        _cleanup(input, completer, result is Uint8List ? result : null);
      });
      reader.onError.first.then((_) => _cleanup(input, completer, null));
      reader.readAsArrayBuffer(files[0]);
    });

    input.click();
    return completer.future;
  }

  static void _cleanup(
    html.FileUploadInputElement input,
    Completer<Uint8List?> completer,
    Uint8List? result,
  ) {
    try { input.remove(); } catch (_) {}
    if (!completer.isCompleted) completer.complete(result);
  }

  /// Compresses [bytes] and uploads to Firebase Storage under [basePath].
  /// Returns the public download URL.
  static Future<String> uploadBytes(
    Uint8List bytes,
    String basePath, {
    ImageCompressPreset preset = ImageCompressPreset.location,
  }) async {
    final ext = _detectExtension(bytes);
    final isGif = ext == 'gif';

    final uploadBytes = isGif ? bytes : await _compress(bytes, preset);
    final contentType = isGif ? 'image/gif' : 'image/jpeg';
    final uploadExt = isGif ? 'gif' : 'jpg';

    final uniqueId = const Uuid().v4();
    final ref = _storage.ref('$basePath/$uniqueId.$uploadExt');
    await ref.putData(uploadBytes, SettableMetadata(contentType: contentType));
    return await ref.getDownloadURL();
  }

  /// Detects image format from magic bytes.
  static String _detectExtension(Uint8List bytes) {
    if (bytes.length >= 10) {
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return 'gif';
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) return 'png';
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';
      if (bytes[0] == 0x52 && bytes[1] == 0x49 &&
          bytes[8] == 0x57 && bytes[9] == 0x45) return 'webp';
    }
    return 'jpg';
  }

  /// Resizes and re-encodes as JPEG using the browser Canvas API.
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
      imgEl.onError.first.then((_) => loadCompleter.completeError('load failed'));
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
      final compressed = base64Decode(dataUrl.split(',').last);

      return compressed.length < bytes.length
          ? Uint8List.fromList(compressed)
          : bytes;
    } catch (_) {
      return bytes;
    }
  }

  /// Deletes an image from Firebase Storage by its download URL.
  static Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
