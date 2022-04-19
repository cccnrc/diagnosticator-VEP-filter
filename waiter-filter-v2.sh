#!/usr/bin/env bash

DIR='/home/VEP_INPUT'

### this is to stringize CONSEQUENCE filters
function stringize_filters {
  F=$1
  IFS=',' read -r -a ARR <<< "$F"
  FF=()
  i=0
  for A in "${ARR[@]}"; do
    AA=$( echo "$A" | cut -d'(' -f1 | xargs )
    if [ $i -eq 0 ]; then
      FF+=("ClinVar_CLNSIG matches athogenic or (not Consequence matches $AA")
    else
      FF+=("and not Consequence matches $AA")
    fi
    i=$((i+1))
  done
  FFS="${FF[@]}"
  echo "${FFS}"
}

### this is to stringize AF filters
function stringize_AF {
  AF=$1
  POP_STRING='AF,AFR_AF,AMR_AF,EAS_AF,EUR_AF,SAS_AF,AA_AF,EA_AF,gnomAD_AF,gnomAD_AFR_AF,gnomAD_AMR_AF,gnomAD_ASJ_AF,gnomAD_EAS_AF,gnomAD_FIN_AF,gnomAD_NFE_AF,gnomAD_OTH_AF,gnomAD_SAS_AF,MAX_AF,1000Gp3_AF,1000Gp3_AFR_AC,1000Gp3_AFR_AF,1000Gp3_AMR_AF,1000Gp3_EAS_AF,1000Gp3_EUR_AF,1000Gp3_SAS_AF,ESP6500_AA_AF,ESP6500_EA_AF,ExAC_AF,ExAC_AFR_AC,ExAC_AFR_AF,ExAC_AMR_AF,ExAC_Adj_AF,ExAC_EAS_AF,ExAC_FIN_AF,ExAC_NFE_AF,ExAC_SAS_AF,UK10K_AF,gnomAD_exomes_AFR_AF,gnomAD_exomes_AMR_AF,gnomAD_exomes_ASJ_AF,gnomAD_exomes_EAS_AF,gnomAD_exomes_FIN_AF,gnomAD_exomes_NFE_AF,gnomAD_exomes_POPMAX_AF,gnomAD_exomes_SAS_AF,gnomAD_exomes_controls_AF,gnomAD_genomes_AFR_AF,gnomAD_genomes_AMR_AF,gnomAD_genomes_ASJ_AF,gnomAD_genomes_EAS_AF,gnomAD_genomes_FIN_AF,gnomAD_genomes_NFE_AF,gnomAD_genomes_POPMAX_AF'
  IFS=',' read -r -a POP_ARRAY <<< "$POP_STRING"
  PP=()
  for P in "${POP_ARRAY[@]}"; do
  PP+=(" and (not $P or $P < $AF)")
  done
  PPS="${PP[@]}"
  echo "${PPS}"
}


while true; do
  COUNT=$( ls -1 $DIR/*.input 2>/dev/null | wc -l )
  if [ $COUNT -gt 0 ]; then
    if [ -d "${DIR}/analisi_result" ]; then
      rm -rf "${DIR}/analisi_result"
    fi
    INPUT_FILE=$( ls -t $DIR/*.input 2>/dev/null | head -n1 )
    FILTERS=$( awk -F'\t' '{ print $1 }' $INPUT_FILE )
    FILTERS_CONS_STRING="$( stringize_filters "$FILTERS" )"
    INPUT="${DIR}/$( awk -F'\t' '{ print $2 }' $INPUT_FILE )"
    GENELIST=$( awk -F'\t' '{ print $3 }' $INPUT_FILE )
    AF_FILTER=$( awk -F'\t' '{ print $4 }' $INPUT_FILE )
    FILTERS_AF_STRING="$( stringize_AF "$AF_FILTER" )"
    FILTERS_STRING="${FILTERS_CONS_STRING}${FILTERS_AF_STRING})"
    OUTPUT="$( dirname $INPUT )/$( basename $INPUT .vcf ).FILTERED.vcf"
    FILTER_COMMAND="./filter_vep \
                         --input_file $INPUT \
                         --format vcf \
                         --force_overwrite \
                         --filter \"$FILTERS_STRING\" \
                         -o $OUTPUT"
     echo -e "  - INPUT:\t$INPUT_FILE"
     echo -e "    - VCF:\t$INPUT"
     echo -e "    - CONS:\t$FILTERS_CONS_STRING"
     echo -e "    - POP:\t$FILTERS_AF_STRING"
     echo -e "    - COMMAND:\t$FILTER_COMMAND"
     eval $FILTER_COMMAND
     wait
     mv $INPUT_FILE "$( dirname $INPUT_FILE )/$( basename $INPUT_FILE .input ).output"
     echo "    - done: $OUTPUT"
     sleep 1
     echo -e "$( basename ${OUTPUT} )\t${GENELIST}\t${AF_FILTER}" > "$( dirname $INPUT )/$( basename ${INPUT_FILE} .input ).asilo_input"
  else
    echo "  - NO INPUT file"
    sleep 10
  fi
done


























exit 0
