#!/bin/bash
# Usage: ./get_slice_bed_gstar.sh -o OUT_FILE GSTAR_FILE1 [GSTAR_FILE2...]

OUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o) OUT="$2"; shift 2 ;;
        *) break ;;
    esac
done

if [[ -z "$OUT" || $# -eq 0 ]]; then
    echo "Usage: $0 -o OUT_FILE GSTAR_FILE1 [GSTAR_FILE2...]"
    exit 1
fi

awk 'BEGIN{FS=OFS="\t"}
FNR==1 {
  if (FILENAME ~ /21nt/) size="21"
  else if (FILENAME ~ /22nt/) size="22"
  else if (FILENAME ~ /23nt/) size="23"
  else size="NA"
}
/^#/ {next}
$1=="Query" {next}
NF < 9 {next}
{
  query=$1; transcript_full=$2; tstart=$3; tstop=$4; tslice=$5
  mferatio=$8; allen=$9
  if (allen >= 10) next
  transcript=transcript_full; sub(/::.*/, "", transcript)
  region=transcript_full; sub(/^.*::/, "", region)
  chr=region; sub(/:.*/, "", chr)
  coords=region; sub(/^[^:]+:/, "", coords); sub(/\(.*/, "", coords)
  split(coords,a,"-"); region_start=a[1]; region_end=a[2]
  strand=region; sub(/^.*\(/, "", strand); sub(/\).*/, "", strand)
  if (strand == "+") { gpos = region_start + tslice - 1 }
  else if (strand == "-") { gpos = region_end - tslice + 1 }
  else { next }
  print chr, gpos-1, gpos, query "|" transcript "|" size "nt", allen, strand, transcript, tslice, mferatio, tstart, tstop
}' "$@" | sort -k1,1 -k2,2n > "$OUT"
