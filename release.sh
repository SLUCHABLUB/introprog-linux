#!/usr/bin/env bash
set -Eeuo pipefail

# release.sh
# Skapar och pushar en annoterad tagg: release-YYYY-MM-DD (dagens datum)
# GitHub Actions-workflow kan lyssna på mönster som 'release-[0-9][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]'.

REMOTE="origin"

usage() {
  cat <<'USAGE'
Usage:
  release.sh [-m "message"] [-r <remote>] [-y]

Options:
  -m  Taggmeddelande (annoterad tag). Om utelämnas öppnas editor.
  -r  Git remote (default: origin)
  -y  Svara "ja" på alla frågor (överskriv tagg utan att fråga)
  -h  Visa denna hjälp

Exempel:
  ./release.sh
  ./release.sh -m "HT25 unix-x release"
  ./release.sh -r origin -y
USAGE
}

confirm() {
  local prompt="${1:-Är du säker? (y/N) }"
  read -r -p "$prompt" ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

delete_tag_if_exists() {
  local tag="$1"
  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "Taggen $tag finns redan lokalt."
    if $ASSUME_YES || confirm "Vill du ersätta taggen $tag? (y/N) "; then
      git tag -d "$tag" || true
      if git ls-remote --tags "$REMOTE" | grep -q "refs/tags/$tag$"; then
        git push "$REMOTE" --delete "$tag" || true
      fi
    else
      echo "Avbryter."
      exit 1
    fi
  else
    # Om den inte finns lokalt, kolla endast remote
    if git ls-remote --tags "$REMOTE" | grep -q "refs/tags/$tag$"; then
      echo "Taggen $tag finns på remote."
      if $ASSUME_YES || confirm "Vill du ersätta taggen $tag på remote? (y/N) "; then
        git push "$REMOTE" --delete "$tag" || true
      else
        echo "Avbryter."
        exit 1
      fi
    fi
  fi
}

MESSAGE=""
ASSUME_YES=false

while getopts ":m:r:yh" opt; do
  case "$opt" in
    m) MESSAGE="$OPTARG" ;;
    r) REMOTE="$OPTARG" ;;
    y) ASSUME_YES=true ;;
    h) usage; exit 0 ;;
    \?) echo "Okänd flagga: -$OPTARG"; usage; exit 1 ;;
    :) echo "Flagga -$OPTARG kräver ett värde."; usage; exit 1 ;;
  esac
done

# Datum i lokal tidzon, ISO-format YYYY-MM-DD
DATE="$(date +%F)"
TAG="release-${DATE}"

# Hämta taggar
git fetch --tags "$REMOTE" >/dev/null 2>&1 || true

echo "Sammanfattning:"
echo "  Datum:  $DATE"
echo "  Tagg:   $TAG"
echo "  Remote: $REMOTE"
$ASSUME_YES || confirm "Skapa och pusha taggen nu? (y/N) " || { echo "Avbrutet."; exit 1; }

# Ta bort befintlig tagg (lokalt/remote) vid behov
delete_tag_if_exists "$TAG"

# Om inget -m: öppna editor för att skriva ett meddelande
if [[ -z "$MESSAGE" ]]; then
  tmpfile="$(mktemp)"
  {
    echo "Release $DATE"
    echo
    echo "(Skriv ditt meddelande ovan. Ta inte bort sista raden.)"
    echo "---"
  } > "$tmpfile"

  EDITOR_CMD="${GIT_EDITOR:-${VISUAL:-${EDITOR:-nano}}}"
  "$EDITOR_CMD" "$tmpfile"

  MESSAGE="$(sed '/^---$/,$d' "$tmpfile" | sed -e '${/^$/d}')"
  rm -f "$tmpfile"
  [[ -z "$MESSAGE" ]] && MESSAGE="Release $DATE"
fi


# Skapa annoterad tagg
git tag -a "$TAG" -m "$MESSAGE"

# Pusha
git push "$REMOTE" "$TAG"

echo "Klart! Taggen $TAG skapades och pushades till $REMOTE."
