import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Provides utilities to keep captured images within backend limits.
class ImageCompressionService {
  static const int defaultMaxBytes = 350 * 1024; // 512 KB
  static const int _initialQuality = 95;
  static const int _minQuality = 45;
  static const int _qualityStep = 5;

  /// Ensure the provided [XFile] stays below [maxBytes] by compressing in place.
  static Future<File> ensureForXFile(
    XFile xFile, {
    int maxBytes = defaultMaxBytes,
  }) async {
    final file = File(xFile.path);
    return ensureForFile(file, maxBytes: maxBytes);
  }

  /// Ensure the file located at [path] stays under [maxBytes].
  static Future<String> ensureForPath(
    String path, {
    int maxBytes = defaultMaxBytes,
  }) async {
    final file = await ensureForFile(File(path), maxBytes: maxBytes);
    return file.path;
  }

  /// Compress the given [file] if it exceeds [maxBytes], returning the same file
  /// reference so existing paths remain valid.
  static Future<File> ensureForFile(
    File file, {
    int maxBytes = defaultMaxBytes,
  }) async {
    if (!await file.exists()) {
      return file;
    }

    var currentSize = await file.length();
    if (currentSize <= maxBytes) {
      return file;
    }

    XFile? bestResult;
    var quality = _initialQuality;

    while (quality >= _minQuality) {
      final tempPath = await _buildTempPath();
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        tempPath,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (compressed == null) {
        break;
      }

      bestResult = compressed;
      currentSize = await File(compressed.path).length();

      if (currentSize <= maxBytes) {
        break;
      }

      quality -= _qualityStep;
    }

    if (bestResult == null) {
      return file;
    }

    final bestFile = File(bestResult.path);
    final bytes = await bestFile.readAsBytes();
    await file.writeAsBytes(bytes, flush: true);

    try {
      await bestFile.delete();
    } catch (_) {
      // Best-effort cleanup; ignore failures.
    }

    return file;
  }

  static Future<String> _buildTempPath() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(tempDir.path, 'cmp_$timestamp.jpg');
  }
}
