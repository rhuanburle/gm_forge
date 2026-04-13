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

  const ImageCompressPreset({required this.maxDimension, required this.quality});
  final int maxDimension;
  final int quality;
}

class ImageUploadService {
  static final _storage = FirebaseStorage.instance;

  /// Opens a native file picker and returns the raw image bytes.
  /// Returns null if the user cancels.
  static Future<Uint8List?> pickImageBytes() async {
    final completer = Completer<Uint8List?>();

    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..style.display = 'none';
    html.document.body!.append(input);

    input.onChange.first.then((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        _done(input, completer, null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.first.then((_) {
        final result = reader.result;
        _done(input, completer, result is Uint8List ? result : null);
      });
      reader.onError.first.then((_) => _done(input, completer, null));
      reader.readAsArrayBuffer(files[0]);
    });

    input.click();
    return completer.future;
  }

  static void _done(
    html.FileUploadInputElement input,
    Completer<Uint8List?> completer,
    Uint8List? result,
  ) {
    try { input.remove(); } catch (_) {}
    if (!completer.isCompleted) completer.complete(result);
  }

  /// Compresses [bytes] then uploads to Firebase Storage under [basePath].
  /// Returns the public download URL.
  static Future<String> uploadBytes(
    Uint8List bytes,
    String basePath, {
    ImageCompressPreset preset = ImageCompressPreset.location,
  }) async {
    final isGif = _detectMimeType(bytes) == 'image/gif';

    final toUpload = isGif ? bytes : await _compress(bytes, preset);
    final contentType = isGif ? 'image/gif' : 'image/jpeg';
    final ext = isGif ? 'gif' : 'jpg';

    final ref = _storage.ref('$basePath/${const Uuid().v4()}.$ext');
    await ref.putData(toUpload, SettableMetadata(contentType: contentType));
    return await ref.getDownloadURL();
  }

  /// Resizes + re-encodes as JPEG using the browser Canvas API.
  /// Uses a data: URL as src to avoid html.Blob() reliability issues.
  /// Falls back to original bytes on any error or timeout.
  static Future<Uint8List> _compress(
    Uint8List bytes,
    ImageCompressPreset preset,
  ) async {
    try {
      final mime = _detectMimeType(bytes);
      final imgEl = html.ImageElement();
      final loadCompleter = Completer<void>();

      imgEl.onLoad.first.then((_) {
        if (!loadCompleter.isCompleted) loadCompleter.complete();
      });
      imgEl.onError.first.then((_) {
        if (!loadCompleter.isCompleted) {
          loadCompleter.completeError('decode failed');
        }
      });

      // data: URL is always readable — avoids html.Blob() silent failures
      imgEl.src = 'data:$mime;base64,${base64Encode(bytes)}';

      await loadCompleter.future.timeout(const Duration(seconds: 10));

      final srcW = imgEl.naturalWidth ?? 0;
      final srcH = imgEl.naturalHeight ?? 0;
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

      final outUrl = canvas.toDataUrl('image/jpeg', preset.quality / 100.0);
      final compressed = Uint8List.fromList(base64Decode(outUrl.split(',').last));

      return compressed.length < bytes.length ? compressed : bytes;
    } catch (_) {
      return bytes;
    }
  }

  static String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3) {
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return 'image/gif';
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) return 'image/png';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
    return 'image/jpeg';
  }

  /// Deletes an image from Firebase Storage by its download URL.
  static Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
