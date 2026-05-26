
#!/bin/bash
# Usage: ./cleave_tx_to_bed.sh -phasfa PHASFA -degfa DEGFA -txfa TXFA -out OUT_BED

PHASFA="" DEGFA="" TXFA="" OUT_BED=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -phasfa) PHASFA="$2"; shift 2 ;;
        -degfa) DEGFA="$2"; shift 2 ;;
        -txfa) TXFA="$2"; shift 2 ;;
        -out) OUT_BED="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$PHASFA" || -z "$DEGFA" || -z "$TXFA" || -z "$OUT_BED" ]]; then
    echo "Usage: $0 -phasfa PHASFA -degfa DEGFA -txfa TXFA -out OUT_BED"
    exit 1
fi

export PATH=/hpc-home/vef25hok/CleaveLand4-4.5/GSTAr_v1-0:$PATH
perl /hpc-home/vef25hok/CleaveLand4-4.5/CleaveLand4.pl -u "$PHASFA" -t -e "$DEGFA" -n "$TXFA" > "${OUT_BED}.tmp"

awk 'BEGIN{FS=OFS="\t"}
/^#/ {next}
$1=="SiteID" {next}
NF < 16 {next}
{
  site_id=$1; query=$2; transcript_full=$3; tstart=$4; tstop=$5; tslice=$6
  mferatio=$9; allen=$10; deg_cat=$15; deg_pval=$16
  transcript=transcript_full; sub(/::.*/, "", transcript)
  region=transcript_full; sub(/^.*::/, "", region)
  chr=region; sub(/:.*/, "", chr)
  coords=region; sub(/^[^:]+:/, "", coords); sub(/\(.*/, "", coords)
  split(coords,a,"-"); region_start=a[1]; region_end=a[2]
  strand=region; sub(/^.*\(/, "", strand); sub(/\).*/, "", strand)
  if (strand == "+") { gpos = region_start + tslice - 1 }
  else if (strand == "-") { gpos = region_end - tslice + 1 }
  else { next }
  print chr, gpos-1, gpos, query "|" transcript "|cat=" deg_cat "|pval=" deg_pval, deg_pval, strand, transcript, tslice, mferatio, tstart, tstop, deg_cat, site_id
}' "${OUT_BED}.tmp" | sort -k1,1 -k2,2n > "$OUT_BED"
rm "${OUT_BED}.tmp"
