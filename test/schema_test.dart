import 'package:beneficiaries/schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a v1 file gets prefs and the current version', () {
    final out = migrate({'version': 1, 'people': []});
    expect(out['version'], kSchemaVersion);
    expect(out['prefs'], equals({}));
    expect(out['people'], equals([]));
  });

  test('a file without a version counts as v1', () {
    expect(schemaVersionOf({'people': []}), 1);
    expect(migrate({'people': []})['version'], kSchemaVersion);
  });

  test('existing prefs are kept', () {
    final out = migrate({'version': 1, 'prefs': {'lastBank': 'okash'}});
    expect(out['prefs'], equals({'lastBank': 'okash'}));
  });

  test('the current version is left as it is', () {
    final input = {'version': kSchemaVersion, 'prefs': {'a': 1}, 'people': []};
    expect(migrate(input), equals(input));
  });

  test('a newer file is returned unchanged, version included', () {
    final input = {'version': 99, 'people': [], 'future': true};
    final out = migrate(input);
    expect(out['version'], 99);
    expect(out['future'], true);
    expect(out.containsKey('prefs'), isFalse);
  });

  test('migrate does not modify its input', () {
    final input = {'version': 1, 'people': []};
    migrate(input);
    expect(input.containsKey('prefs'), isFalse);
  });
}
