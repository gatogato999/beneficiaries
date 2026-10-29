# Contributing

Thank you for helping. The most useful contributions are bank format corrections and bug reports.

## Wrong or missing bank format

Open an issue with the "Wrong or missing bank format" template. Say which bank or wallet, how many digits the account has, and the BBAN format your bank accepted. Replace the account digits with X. **Never post a real account number.**

## Code changes

1. Fork the repository and create a branch.
2. Set up as described under "Build from source" in the README.
3. `flutter analyze` and `flutter test` must pass. Bank rules live in `lib/banks.dart`; add or update a test in `test/banks_test.dart` with an example you have verified.
4. Keep dependencies minimal (only `path_provider` and `share_plus` today). Open an issue before adding a package.
5. Keep the app private: no analytics, no network code, and no new permissions without discussion.
6. The interface is Arabic (right to left); write new user-facing text in Arabic.
7. Open a pull request using the template.
