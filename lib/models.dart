import 'dart:math';

final _rnd = Random();
String newId() => '${DateTime.now().microsecondsSinceEpoch}${_rnd.nextInt(99999)}';

enum Resolution { merge, separate, skip, later }

class Account {
  String bankId, number;
  Account(this.bankId, this.number);

  /// Identity of an account: same bank + same number (leading zeros ignored).
  String get key => '$bankId:${number.replaceFirst(RegExp(r'^0+'), '')}';

  Map<String, dynamic> toJson() => {'bank': bankId, 'number': number};
  factory Account.fromJson(Map<String, dynamic> j) =>
      Account('${j['bank'] ?? ''}', '${j['number'] ?? ''}');
}

class Person {
  String id, name;
  List<Account> accounts;

  /// Personal flag: kept on this phone only, never part of an exported file.
  bool pinned;
  Person(this.id, this.name, this.accounts, {this.pinned = false});

  /// `shared: true` is the form that goes into export files: no id and no personal flags.
  Map<String, dynamic> toJson({bool shared = false}) => {
        if (!shared) 'id': id,
        if (!shared && pinned) 'pinned': true,
        'name': name,
        'accounts': accounts.map((a) => a.toJson()).toList(),
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        '${j['id'] ?? newId()}',
        '${j['name'] ?? ''}'.trim(),
        ((j['accounts'] ?? []) as List)
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList(),
        pinned: j['pinned'] == true,
      );
}

/// An imported record waiting for the user's decision.
class Pending {
  final Person incoming;
  final String localId;
  Pending(this.incoming, this.localId);

  Map<String, dynamic> toJson() => {'incoming': incoming.toJson(), 'local': localId};
  factory Pending.fromJson(Map<String, dynamic> j) =>
      Pending(Person.fromJson(j['incoming'] as Map<String, dynamic>), '${j['local']}');
}

String normName(String s) => s
    .replaceAll(RegExp('[\u064B-\u0652\u0640]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .toLowerCase();
