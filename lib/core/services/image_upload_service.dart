// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Controls compression settings per image context.
/// Kept for API compatibility — compression is handled server-side or skipped.
enum ImageCompressPreset {
  map(maxDimension: 1920, quality: 85),
  location(maxDimension: 1280, quality: 82),
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

  /// Uploads [bytes] directly to Firebase Storage under [basePath].
  /// Returns the public download URL.
  static Future<String> uploadBytes(
    Uint8List bytes,
    String basePath, {
    ImageCompressPreset preset = ImageCompressPreset.location,
  }) async {
    final contentType = _detectMimeType(bytes);
    final ext = contentType == 'image/gif' ? 'gif' : 'jpg';

    final uniqueId = const Uuid().v4();
    final ref = _storage.ref('$basePath/$uniqueId.$ext');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return await ref.getDownloadURL();
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
