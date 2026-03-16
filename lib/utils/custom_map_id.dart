const int customMapKey6HexLength = 12;

String? normalizeCustomMapId(String? mapId) {
  if (mapId == null) {
    return null;
  }

  final normalized = mapId.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.length <= customMapKey6HexLength) {
    return normalized;
  }

  return normalized.substring(0, customMapKey6HexLength);
}
