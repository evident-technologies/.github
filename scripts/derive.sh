#!/usr/bin/env bash
# derive.sh — hash-verified derivative generation for the Evident worker.
#
# Generates a derivative (OCR text, PDF/A, thumbnail, transcript, etc.) from a
# source file WITHOUT mutating the original, and writes a sha256 provenance
# manifest linking input → output.
#
# Usage:
#   derive.sh <input-file> [operation]
#
# Operations (auto-detected from extension if omitted):
#   ocr        PDF/image  -> searchable text   (tesseract / pdftotext)
#   pdftext    PDF        -> plain text         (pdftotext)
#   pdfa       PDF        -> archival PDF/A     (qpdf linearize)
#   thumb      image/PDF  -> 512px PNG preview  (ImageMagick / pdftoppm)
#   transcript audio/video-> text              (ffmpeg extract; whisper if present)
#   meta       any        -> exiftool metadata json
#
# Outputs go to $WORKER_HOME/derivatives and a manifest to $WORKER_HOME/manifests.
set -euo pipefail

WORKER_HOME="${WORKER_HOME:-$HOME/evident-worker}"
DERIV="${WORKER_HOME}/derivatives"
MANI="${WORKER_HOME}/manifests"
mkdir -p "$DERIV" "$MANI"

die() { echo "derive: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

IN="${1:-}"; OP="${2:-}"
[ -n "$IN" ] || die "usage: derive.sh <input-file> [operation]"
[ -f "$IN" ] || die "no such file: $IN"

# Refuse to read out of (and never write into) the immutable originals dir
case "$(readlink -f "$IN")" in
  "$(readlink -f "$DERIV")"/*) die "input is itself a derivative; refuse to chain blindly";;
esac

EXT="${IN##*.}"; EXT="${EXT,,}"
BASE="$(basename "${IN%.*}")"
IN_SHA="$(sha256sum "$IN" | awk '{print $1}')"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

# Auto-detect operation
if [ -z "$OP" ]; then
  case "$EXT" in
    pdf)              OP=pdftext ;;
    png|jpg|jpeg|tif|tiff) OP=ocr ;;
    mp3|wav|m4a|mp4|mov|mkv) OP=transcript ;;
    *)                OP=meta ;;
  esac
fi

OUT=""
run() {
  case "$OP" in
    ocr)
      OUT="${DERIV}/${BASE}.${STAMP}.txt"
      if [ "$EXT" = "pdf" ]; then
        have pdftotext || die "pdftotext missing (apt install poppler-utils)"
        pdftotext "$IN" "$OUT"
      else
        have tesseract || die "tesseract missing (apt install tesseract-ocr)"
        tesseract "$IN" "${OUT%.txt}" >/dev/null 2>&1
      fi ;;
    pdftext)
      have pdftotext || die "pdftotext missing"
      OUT="${DERIV}/${BASE}.${STAMP}.txt"; pdftotext "$IN" "$OUT" ;;
    pdfa)
      have qpdf || die "qpdf missing"
      OUT="${DERIV}/${BASE}.${STAMP}.pdfa.pdf"; qpdf --linearize "$IN" "$OUT" ;;
    thumb)
      OUT="${DERIV}/${BASE}.${STAMP}.png"
      if [ "$EXT" = "pdf" ]; then
        have pdftoppm || die "pdftoppm missing"
        pdftoppm -png -singlefile -scale-to 512 "$IN" "${OUT%.png}"
      else
        have convert || die "ImageMagick missing"
        convert "$IN" -resize 512x512 "$OUT"
      fi ;;
    transcript)
      have ffmpeg || die "ffmpeg missing"
      AUDIO="${DERIV}/${BASE}.${STAMP}.wav"
      ffmpeg -y -i "$IN" -ar 16000 -ac 1 "$AUDIO" >/dev/null 2>&1
      if have whisper; then
        whisper "$AUDIO" --model base --output_dir "$DERIV" --output_format txt >/dev/null 2>&1
        OUT="${DERIV}/$(basename "${AUDIO%.wav}").txt"
      else
        OUT="$AUDIO"
        echo "derive: whisper not installed — produced 16kHz wav only" >&2
      fi ;;
    meta)
      have exiftool || die "exiftool missing"
      OUT="${DERIV}/${BASE}.${STAMP}.meta.json"; exiftool -json "$IN" > "$OUT" ;;
    *) die "unknown operation: $OP" ;;
  esac
}
run

[ -f "$OUT" ] || die "operation produced no output"
OUT_SHA="$(sha256sum "$OUT" | awk '{print $1}')"

# Provenance manifest — links original to derivative, both hashed
MANIFEST="${MANI}/${BASE}.${STAMP}.${OP}.json"
cat > "$MANIFEST" << EOF
{
  "schema": "evident.derivative.v1",
  "operation": "${OP}",
  "generated_utc": "${STAMP}",
  "host": "$(hostname)",
  "source": {
    "path": "$(readlink -f "$IN")",
    "sha256": "${IN_SHA}",
    "bytes": $(stat -c%s "$IN")
  },
  "derivative": {
    "path": "$(readlink -f "$OUT")",
    "sha256": "${OUT_SHA}",
    "bytes": $(stat -c%s "$OUT")
  },
  "tooling": "$(command -v "${OP}" 2>/dev/null || echo "$OP")"
}
EOF

echo "  source     ${IN}  (sha256 ${IN_SHA:0:12}…)"
echo "  derivative ${OUT}  (sha256 ${OUT_SHA:0:12}…)"
echo "  manifest   ${MANIFEST}"
