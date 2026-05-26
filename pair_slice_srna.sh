#!/bin/bash
# Usage: ./pair_slice_srna.sh -srna SRNA_TX_BED -slice SLICE_BED -o OUT_SLICE

SRNA_TX_BED="" SLICE_BED="" OUT_SLICE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -srna) SRNA_TX_BED="$2"; shift 2 ;;
        -slice) SLICE_BED="$2"; shift 2 ;;
        -o) OUT_SLICE="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$SRNA_TX_BED" || -z "$SLICE_BED" || -z "$OUT_SLICE" ]]; then
    echo "Usage: $0 -srna SRNA_TX_BED -slice SLICE_BED -o OUT_SLICE"
    exit 1
fi

OUT_PAIRS="${OUT_SLICE}.tmp"

awk 'BEGIN{FS=OFS="\t"}
NR==FNR {
  split($4,a,"|"); tx=a[1]
  n[tx]++; s_chr[tx,n[tx]]=$1; s_start[tx,n[tx]]=$2; s_end[tx,n[tx]]=$3
  s_name[tx,n[tx]]=$4; s_score[tx,n[tx]]=$5; s_strand[tx,n[tx]]=$6
  next
}
{
  slice_chr=$1; slice_start=$2; slice_end=$3; slice_name=$4
  slice_score=$5; slice_strand=$6; tx=$7
  if (!(tx in n)) next
  for (i=1; i<=n[tx]; i++) {
    if (slice_chr != s_chr[tx,i]) next
    dist = s_start[tx,i] - slice_end
    if (dist >= 0 && dist <= 421) {
      print slice_chr, slice_start, slice_end, slice_name, slice_score, slice_strand, tx,
            s_chr[tx,i], s_start[tx,i], s_end[tx,i], s_name[tx,i], s_score[tx,i], s_strand[tx,i], dist
    }
  }
}' "$SRNA_TX_BED" "$SLICE_BED" | sort -k7,7 -k1,1 -k2,2n -k9,9n > "$OUT_PAIRS"

awk 'BEGIN{FS=OFS="\t"}
{
  key=$1 FS $2 FS $3 FS $4 FS $5 FS $6 FS $7
  if (!(key in best_dist) || $14 < best_dist[key]) {
    best_dist[key]=$14; best_line[key]=$0
  }
}
END {
  for (key in best_line) {
    split(best_line[key],f,FS)
    print f[1], f[2], f[3], f[4] "|left_of_sRNA=" f[14] "|" f[11], f[5], f[6]
  }
}' "$OUT_PAIRS" | sort -k1,1 -k2,2n > "$OUT_SLICE"
rm "$OUT_PAIRS"
