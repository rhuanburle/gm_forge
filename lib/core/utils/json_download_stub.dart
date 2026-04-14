// Stub implementation for non-web platforms.
// On mobile/desktop, the caller falls back to clipboard copy.
void downloadJsonFile(String content, String filename) {
  // No-op on non-web. Clipboard fallback handled by the caller.
}
