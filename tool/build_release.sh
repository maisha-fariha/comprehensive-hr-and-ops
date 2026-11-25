#!/usr/bin/env bash
#
# Release build with an automatic version bump.
#
#   tool/build_release.sh                 # +1 build number, release APK
#   tool/build_release.sh --aab           # +1 build number, Play Store bundle
#   tool/build_release.sh --bump patch    # 1.0.0+4 -> 1.0.1+5  (or minor / major)
#   tool/build_release.sh --no-bump       # build without touching the version
#   tool/build_release.sh --dry-run       # show the next version, change nothing
#
# The build number (the part after "+" in pubspec.yaml) is Android's
# versionCode and must rise on every release. If the build fails, pubspec.yaml
# is restored, so a failed build never burns a number. Nothing is committed.
set -euo pipefail

cd "$(dirname "$0")/.."

target="apk"
bump=""
dry_run=false
no_bump=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apk) target="apk" ;;
    --aab) target="appbundle" ;;
    --bump)
      bump="${2:-}"
      [[ "$bump" =~ ^(major|minor|patch)$ ]] || { echo "--bump needs major|minor|patch" >&2; exit 2; }
      shift ;;
    --no-bump) no_bump=true ;;
    --dry-run) dry_run=true ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

line=$(grep -E '^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+' pubspec.yaml | head -1 || true)
[[ -n "$line" ]] || { echo "pubspec.yaml needs 'version: X.Y.Z+N'" >&2; exit 1; }

current=$(echo "$line" | sed -E 's/^version:[[:space:]]*//')
name=${current%%+*}
build=${current##*+}
IFS=. read -r major minor patch <<<"$name"

next_build=$((build + 1))
case "$bump" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac
next_name="$major.$minor.$patch"
next="$next_name+$next_build"

if $no_bump; then
  next="$current"
fi

echo "Version: $current  ->  $next  ($target, release)"
if $dry_run; then
  echo "Dry run: nothing changed."
  exit 0
fi

backup=$(mktemp)
cp pubspec.yaml "$backup"
restore() { cp "$backup" pubspec.yaml; rm -f "$backup"; }

if ! $no_bump; then
  # Top-level `version:` only (dependency versions are indented).
  perl -pi -e "s/^version:\\s*\\S+/version: $next/" pubspec.yaml
fi

if flutter build "$target" --release; then
  rm -f "$backup"
else
  echo "Build failed - restoring pubspec.yaml ($current)." >&2
  restore
  exit 1
fi

case "$target" in
  apk) out="build/app/outputs/flutter-apk/app-release.apk" ;;
  appbundle) out="build/app/outputs/bundle/release/app-release.aab" ;;
esac
echo
echo "Built $next"
echo "Output: $out"
echo "Remember to commit the pubspec.yaml version change."
