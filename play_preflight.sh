#!/usr/bin/env bash
# Pre-upload checks for Google Play. Run from the Flutter project root:  ./play_preflight.sh
# docs/ (privacy policy, terms) is checked for leftover placeholders; override with PAGES_DIR=...
set -uo pipefail
cd "$(dirname "$0")"
fail=0
ok()   { echo "  [ok]   $*"; }
bad()  { echo "  [FAIL] $*"; fail=1; }
warn() { echo "  [warn] $*"; }
CONTACT=~/.config/sijil/contact.json
PAGES_DIR=${PAGES_DIR:-$PWD/docs}
STORE=~/releases/beneficiaries/store-assets

echo "== 1. Placeholders and secrets"
if [[ -f $CONTACT ]]; then
  grep -qE 'example\.com|0{9}' "$CONTACT" && bad "contact.json still has placeholder values" || ok "contact config present, values look real"
else bad "missing $CONTACT"; fi
for d in lib "$PAGES_DIR"; do
  [[ -d $d ]] || { warn "folder not found, skipped: $d"; continue; }
  if grep -rnE "you@example\.com|\+249000000000|\[CONTACT_EMAIL\]|\[DEVELOPER NAME\]|\[COUNTRY\]|\[EFFECTIVE DATE\]" "$d"; then
    bad "placeholders left in $d"; else ok "no placeholders in $d"; fi
done
if git ls-files | grep -E 'key\.properties|\.jks$|\.keystore$'; then bad "a secret file is tracked by git"; else ok "no key files tracked"; fi
[[ -z "$(git status --porcelain)" ]] && ok "git tree clean" || warn "uncommitted changes"

echo "== 2. Public pages reachable (Play needs an active, non-PDF privacy policy URL)"
for var in kPrivacyUrl kTermsUrl; do
  url=$(grep -oP "$var = '\K[^']+" lib/common.dart || true)
  [[ -n $url ]] || { bad "$var not found in lib/common.dart"; continue; }
  code=$(curl -s -o /dev/null -w '%{http_code}' -L "$url" || echo 000)
  [[ $code == 200 ]] && ok "$url -> 200" || bad "$url -> HTTP $code"
done

echo "== 3. Static analysis"
flutter analyze --no-pub >/tmp/preflight_analyze.log 2>&1 && ok "flutter analyze clean" || { bad "flutter analyze found issues"; tail -15 /tmp/preflight_analyze.log; }

if [[ -d test ]]; then
  flutter test --no-pub >/tmp/preflight_test.log 2>&1 && ok "unit tests pass" || { bad "unit tests failed"; tail -15 /tmp/preflight_test.log; }
else warn "no test/ folder (copy repo_files/test)"; fi

echo "== 4. Release build (arm64)"
flutter build apk --release --split-per-abi --target-platform android-arm64 \
  --dart-define-from-file="$CONTACT" >/tmp/preflight_build.log 2>&1 \
  && ok "release build ok" || { bad "build failed (see /tmp/preflight_build.log)"; tail -15 /tmp/preflight_build.log; }
APK=build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

echo "== 5. APK inspection"
SDK=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}
BT=$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)
if [[ -z $BT || ! -f $APK ]]; then
  bad "build-tools ($SDK) or $APK missing"
else
  B=$("$BT/aapt2" dump badging "$APK" 2>/dev/null)
  echo "$B" | grep -E "^package:|^targetSdkVersion|^sdkVersion" | sed 's/^/         /'
  t=$(echo "$B" | sed -n "s/^targetSdkVersion:'\([0-9]*\)'.*/\1/p")
  [[ ${t:-0} -ge 36 ]] && ok "targetSdk $t (new apps must target 36+)" || bad "targetSdk ${t:-unknown} is below 36"
  perms=$(echo "$B" | grep -E "^uses-permission" || true)
  [[ -z $perms ]] && ok "no permissions requested" || { warn "permissions requested (each needs a justification):"; echo "$perms" | sed 's/^/         /'; }
  echo "$B" | grep -q "application-debuggable" && bad "APK is debuggable" || ok "not debuggable"
  certs=$("$BT/apksigner" verify --print-certs "$APK" 2>&1)
  echo "$certs" | grep -E "Signer #1 certificate (DN|SHA-256)" | sed 's/^/         /'
  echo "$certs" | grep -qi "Android Debug" && bad "signed with the DEBUG key" || ok "not signed with the debug key"
  "$BT/zipalign" -c -P 16 4 "$APK" >/dev/null 2>&1 && ok "native libraries 16 KB aligned" \
    || warn "16 KB alignment check failed, or build-tools older than 35 (Play enforces this from 1 Feb 2027)"
fi

echo "== 6. Version"
v=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')
echo "         pubspec version: $v   last tag: $(git describe --tags --abbrev=0 2>/dev/null || echo none)"

echo "== 7. Store assets in $STORE"
for f in icon-512.png feature-graphic-1024x500.png; do [[ -f $STORE/$f ]] && ok "$f" || warn "missing $f (run make_store_assets.sh)"; done
n=$(ls "$STORE"/screenshots/*.png 2>/dev/null | wc -l)
[[ $n -ge 2 ]] && ok "$n phone screenshots" || warn "need at least 2 phone screenshots (run screenshots.sh)"

echo
[[ $fail -eq 0 ]] && echo "PREFLIGHT PASSED (review the warnings above)" || echo "PREFLIGHT FAILED - fix the [FAIL] lines first"
exit $fail
