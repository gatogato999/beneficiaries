# Changelog
Format: [version+build] - date. Keep one entry per release; the build number always increases.

## [Unreleased]
- Added: sort the list by name, recently used or most used, and filter it by bank (usage is personal and never shared). Searching an account number now requires a digits-only query.
- Added: pin the beneficiaries you use most so they stay at the top (personal, not shared in exports).
- Added: the converter remembers the last bank; a paste button next to the account number.
- Changed: account numbers typed or pasted in Arabic-Indic digits are accepted; data.json now has a schema version (older files are backed up before migrating).
- Added: "undo" after deleting a beneficiary.
- Added: dark mode that follows the phone's setting.
- Changed: beneficiary cards are collapsed by default; a toggle button shows their accounts.
- Added: WhatsApp link for contacting the developer; save-to-device; "open with" support for files sent through WhatsApp; contact details read from a build-time config; per-ABI APKs.
- Added (Play readiness): About screen (version, privacy policy, terms, open-source licences), import size/field limits, serialised saves, cleanup of temporary export files, accessibility tooltips, cleaner manifest, localized app label.

## [1.0.0+1] - 2026-10-21
- Initial release: BBAN converter for 15 banks/wallets, beneficiaries book with search and copy buttons, share/import with merge-or-separate conflict handling.
