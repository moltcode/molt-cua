#!/usr/bin/env bash
# Repack a pinned upstream cua-driver-rs release into per-platform npm-layout
# tarballs (package/ root). Every upstream asset is checked against the
# release's checksums.txt before anything is repacked.
#
#   scripts/repack.sh            # all platforms, output in out/
#
# Prints one line per tarball and writes out/artifacts.json (url, sha256,
# size per npm platform id) for the Molt plugin catalog.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

name=$(jq -r .name package.json)
version=$(jq -r .version package.json)
repo=$(jq -r .molt.upstream.repo package.json)
tag=$(jq -r .molt.upstream.tag package.json)
upstream_version=${tag#cua-driver-rs-v}
base="https://github.com/$repo/releases/download/$tag"
release_base="https://github.com/moltcode/$name/releases/download/v$version"

out=$root/out
work=$root/out/work
rm -rf "$out"
mkdir -p "$work"

fetch() {
  local asset=$1
  if [ ! -f "$work/$asset" ]; then
    curl -fsSL --retry 3 -o "$work/$asset" "$base/$asset"
  fi
  local want got
  want=$(awk -v a="$asset" '$2 == a { print $1 }' "$work/checksums.txt")
  if [ -z "$want" ]; then
    echo "no upstream checksum for $asset" >&2
    exit 1
  fi
  got=$(shasum -a 256 "$work/$asset" | awk '{ print $1 }')
  if [ "$want" != "$got" ]; then
    echo "checksum mismatch for $asset: want $want got $got" >&2
    exit 1
  fi
}

curl -fsSL --retry 3 -o "$work/checksums.txt" "$base/checksums.txt"

skills_asset="cua-driver-rs-v$upstream_version-skills.tar.gz"
fetch "$skills_asset"
mkdir -p "$work/skills"
tar -xzf "$work/$skills_asset" -C "$work/skills"
skills_src=$(find "$work/skills" -name SKILL.md -maxdepth 3 -exec dirname {} \; | head -n 1)

# bundle id -> upstream binary asset
bundles=(
  "darwin:cua-driver-rs-$upstream_version-darwin-universal-binary.tar.gz"
  "linux-x64:cua-driver-rs-$upstream_version-linux-x86_64-binary.tar.gz"
  "linux-arm64:cua-driver-rs-$upstream_version-linux-arm64-binary.tar.gz"
)

echo "{" > "$out/artifacts.json"
first=1

emit() {
  local platform=$1 file=$2 sha=$3 size=$4
  [ $first -eq 1 ] || echo "," >> "$out/artifacts.json"
  first=0
  printf '  "%s": {"url": "%s/%s", "sha256": "%s", "size": %s}' \
    "$platform" "$release_base" "$file" "$sha" "$size" >> "$out/artifacts.json"
}

for entry in "${bundles[@]}"; do
  bundle=${entry%%:*}
  asset=${entry#*:}
  fetch "$asset"

  stage=$work/stage-$bundle
  extract=$work/extract-$bundle
  rm -rf "$stage" "$extract"
  mkdir -p "$stage/package/dist" "$stage/package/skills" "$extract"
  tar -xzf "$work/$asset" -C "$extract"

  driver=$(find "$extract" -type f -name cua-driver | head -n 1)
  if [ -z "$driver" ]; then
    echo "no cua-driver binary in $asset" >&2
    exit 1
  fi
  install -m 0755 "$driver" "$stage/package/dist/cua-driver"
  theme=$(find "$extract" -type f -name cua-cursor-theme | head -n 1)
  if [ -n "$theme" ]; then
    install -m 0755 "$theme" "$stage/package/dist/cua-cursor-theme"
  fi

  cp package.json README.md icon.png "$stage/package/"
  mkdir -p "$stage/package/bin"
  install -m 0755 bin/cua-driver "$stage/package/bin/cua-driver"
  cp -R "$skills_src" "$stage/package/skills/cua-driver"
  scripts/molt-skill-note.sh "$stage/package/skills/cua-driver/SKILL.md"

  file="$name-$version-$bundle.tgz"
  tar -czf "$out/$file" -C "$stage" package
  sha=$(shasum -a 256 "$out/$file" | awk '{ print $1 }')
  size=$(wc -c < "$out/$file" | tr -d ' ')
  echo "$file $sha $size"

  case $bundle in
    darwin)
      emit darwin-arm64 "$file" "$sha" "$size"
      emit darwin-x64 "$file" "$sha" "$size"
      ;;
    *) emit "$bundle" "$file" "$sha" "$size" ;;
  esac
done

printf '\n}\n' >> "$out/artifacts.json"
rm -rf "$work"
