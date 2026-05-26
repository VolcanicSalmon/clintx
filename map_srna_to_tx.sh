#!/bin/bash
# Usage: ./map_srna_to_tx.sh -srna SRNA_BED -tx TXREGION_BED -o OUT_BED

SRNA_BED="" TXREGION_BED="" OUT_BED=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -srna) SRNA_BED="$2"; shift 2 ;;
        -tx) TXREGION_BED="$2"; shift 2 ;;
        -o) OUT_BED="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$SRNA_BED" || -z "$TXREGION_BED" || -z "$OUT_BED" ]]; then
    echo "Usage: $0 -srna SRNA_BED -tx TXREGION_BED -o OUT_BED"
    exit 1
fi

bedtools intersect -a "$SRNA_BED" -b "$TXREGION_BED" -wa -wb \
| awk 'BEGIN{FS=OFS="\t"}
{
  tx=$10; key=tx FS $1 FS $2 FS $3 FS $4 FS $6
  if (!(key in seen)) { seen[key]=1; print $1,$2,$3,tx "|" $4,$5,$6 }
}' | sort -k1,1 -k2,2n > "$OUT_BED"
