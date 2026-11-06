/// Version of the data.json layout. Bump it when the layout changes and add a step to migrate().
const kSchemaVersion = 2;

int schemaVersionOf(Map<String, dynamic> json) => (json['version'] as num?)?.toInt() ?? 1;

/// Upgrades an older data.json map to the current layout. Files from a newer app are returned unchanged.
Map<String, dynamic> migrate(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);
  final from = schemaVersionOf(json);
  if (from < 2) {
    // v2 added "prefs" (small settings such as the last bank chosen in the converter)
    out['prefs'] = out['prefs'] is Map ? out['prefs'] : <String, dynamic>{};
  }
  if (from < kSchemaVersion) out['version'] = kSchemaVersion;
  return out;
}
