import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadJsonFile(String content, String filename) {
  final bytes = utf8.encode(content);
  final jsArray = bytes.toJS;
  final blob = web.Blob(
    [jsArray].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
  anchor.remove();
}
