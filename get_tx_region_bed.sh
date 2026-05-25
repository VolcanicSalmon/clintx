#!/bin/bash
# Usage: ./get_tx_region_bed.sh -gff GFF -tx_list TX_LIST -prefix PREFIX [-f GENOME]

GFF="" TX_LIST="" PREFIX="" GENOME="" RUN_GETFASTA=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -gff) GFF="$2"; shift 2 ;;
        -tx_list) TX_LIST="$2"; shift 2 ;;
        -prefix) PREFIX="$2"; shift 2 ;;
        -f) GENOME="$2"; RUN_GETFASTA=true; shift 2 ;;
        *) echo "not option: $1"; exit 1 ;;
    esac
done

if [[ -z "$GFF" || -z "$TX_LIST" || -z "$PREFIX" ]]; then
    echo "Usage: $0 -gff GFF -tx_list TX_LIST -prefix PREFIX [-f GENOME]"
    exit 1
fi

awk 'BEGIN{FS=OFS="\t"}
NR==FNR { keep[$1]=1; next }
$3=="mRNA" {
  id=""
  n=split($9,a,";")
  for (i=1; i<=n; i++) {
    if (a[i] ~ /^ID=/) { id=a[i]; sub(/^ID=/,"",id) }
  }
  if (id in keep) { print $1, $4-1, $5, id, ".", $7 }
}' "$TX_LIST" "$GFF" | sort -k1,1 -k2,2n > "${PREFIX}_transcript_regions.bed"

if [[ "$RUN_GETFASTA" == true && -n "$GENOME" ]]; then
    bedtools getfasta -fi "$GENOME" -bed "${PREFIX}_transcript_regions.bed" -s -name -fo "${PREFIX}_transcript_regions.fa"
fi
