/// Same rule as vendor/fuse-kit/host/BusinessDeviceId.swift: at most 32 characters.
/// UUIDs lose dashes and become lowercase; long hex keeps the first 32; other long values are rejected.
String narrowBusinessDeviceId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.length <= 32) return trimmed;
  if (_uuid.hasMatch(trimmed)) return trimmed.replaceAll('-', '').toLowerCase();
  final hex = trimmed.toLowerCase();
  if (_hex.hasMatch(hex)) return hex.substring(0, 32);
  return '';
}

final RegExp _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
final RegExp _hex = RegExp(r'^[0-9a-f]+$');
