#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <file> <upload_url> [chunk_size_mb]"
  exit 1
fi

FILE="$1"
UPLOAD_URL="$2"
CHUNK_SIZE_MB="${3:-5}"  

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 1
fi

CHUNK_SIZE_BYTES=$((CHUNK_SIZE_MB * 1024 * 1024))

BASENAME="$(basename "$FILE")"
PREFIX="${BASENAME}.part_"

echo "Splitting '$FILE' into ${CHUNK_SIZE_MB}MB chunks..."
split -b "$CHUNK_SIZE_BYTES" -d -a 4 "$FILE" "$PREFIX"

TOTAL_CHUNKS=${#PARTS[@]}

echo "Total chunks: $TOTAL_CHUNKS"

for i in "${!PARTS[@]}"; do
  PART="${PARTS[$i]}"
  CHUNK_INDEX="$i"

  echo "Uploading chunk $((CHUNK_INDEX + 1))/$TOTAL_CHUNKS: $PART"

  curl -sS -X POST "$UPLOAD_URL" \
    -F "file_id=$BASENAME" \
    -F "chunk_index=$CHUNK_INDEX" \
    -F "total_chunks=$TOTAL_CHUNKS" \
    -F "chunk=@${PART};type=application/octet-stream"

done

echo "Upload complete."
