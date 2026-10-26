import 'dart:convert';
import 'dart:html' as html;

/// Remembers API and media origins so index.html can preconnect on the next launch.
class PreconnectOrigins {
  static const _key = 'fuse_preconnect_origins';
  static const _limit = 4;
  static final Set<String> _seen = {};

  static void note(String? url) {
    if (url == null || url.isEmpty || _seen.length >= _limit) return;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    final origin = uri.origin;
    if (!_seen.add(origin)) return;
    try {
      final stored = html.window.localStorage[_key];
      final list = stored == null ? <String>[] : List<String>.from(jsonDecode(stored) as List);
      if (list.contains(origin)) return;
      list.insert(0, origin);
      html.window.localStorage[_key] = jsonEncode(list.take(_limit).toList());
    } catch (_) {}
  }
}
