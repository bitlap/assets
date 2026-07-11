import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Logo 本地缓存服务：首次下载后缓存到本地文件，后续直接读取本地文件
class LogoCacher {
  static String? _cachePath;
  static final Set<String> _downloading = {};

  /// 初始化缓存目录（应用启动时调用一次）
  static Future<void> ensureInit() async {
    if (_cachePath != null) return;
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/logos',
    );
    debugPrint('LOGO路径 $dir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachePath = dir.path;
  }

  static String _filePath(String code) =>
      '$_cachePath/${code.toUpperCase()}.png';

  /// 同步检查本地缓存，有则返回 FileImage（零延迟）
  static ImageProvider? syncCached(String code) {
    if (_cachePath == null) return null;
    final file = File(_filePath(code));
    if (file.existsSync()) {
      debugPrint('获取缓存图片 ${_filePath(code)}');
      return FileImage(file);
    }
    return null;
  }

  /// 触发后台缓存（fire-and-forget），已缓存或正在下载则跳过
  static void cacheInBackground(String code, String logoUrl) {
    final key = code.toUpperCase();
    if (syncCached(code) != null) return;
    if (_downloading.contains(key)) return;
    _downloading.add(key);
    _downloadToCache(key, logoUrl);
  }

  /// 后台下载图片到本地（fire-and-forget）
  static Future<void> _downloadToCache(String code, String logoUrl) async {
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200) {
        final file = File(_filePath(code));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {}
    _downloading.remove(code);
  }
}
