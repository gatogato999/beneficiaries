#!/usr/bin/env bash
# usage: ./release.sh [keep|patch|minor|major|build]
#   keep  = release the version currently in pubspec.yaml (use for the first release)
#   build = same version name, only +1 on the build number
set -euo pipefail
cd "$(dirname "$0")"
[[ -z "$(git status --porcelain)" ]] || { echo "Commit or stash your changes first."; exit 1; }

cur=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')
name=${cur%+*}; build=${cur#*+}
IFS=. read -r a b c <<<"$name"
case "${1:-patch}" in
  keep)  ;;
  major) name="$((a+1)).0.0"; build=$((build+1)) ;;
  minor) name="$a.$((b+1)).0"; build=$((build+1)) ;;
  patch) name="$a.$b.$((c+1))"; build=$((build+1)) ;;
  build) build=$((build+1)) ;;
  *) echo "usage: $0 [keep|patch|minor|major|build]"; exit 1 ;;
esac
new="$name+$build"
git rev-parse "v$new" >/dev/null 2>&1 && { echo "Tag v$new already exists."; exit 1; }

sed -i "s/^version:.*/version: $new/" pubspec.yaml
flutter clean >/dev/null
flutter build apk --release
flutter build appbundle --release

out=~/releases/beneficiaries/$new
mkdir -p "$out"
cp build/app/outputs/flutter-apk/app-release.apk "$out/sijil-$new.apk"
cp build/app/outputs/bundle/release/app-release.aab "$out/sijil-$new.aab"
(cd "$out" && sha256sum * > SHA256SUMS)

git diff --quiet || git commit -am "Release v$new"
git tag -a "v$new" -m "Release $new"
echo "Built $new -> $out"
