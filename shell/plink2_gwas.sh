#!/bin/bash

# ======= DEFAULT CONFIGURATION ========
VCF_FILE="./data/variants/chr7.HDAC9.vcf"
GENENAME="HDAC-9"
PHENO_FILE="./data/phenotypes/merge_phenos_PCs.txt"
COVARS="PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"
OUTPUT_DIR="./tables"
# PHENO_LIST=("DMOTSCORE_mod" "OSTEOPONIA" "OSTEOPOROSIS" "FXALL" "FXMOF_POST" \
#             "CVALL_POST" "CVMACE_POST" "MCASGLOBAL_PRE_M" "AVCGLOBAL_PRE_M")
PHENO_LIST=("DMOTSCORE_mod")

# =====================================

# ========= PARSE ARGUMENTS ===========
print_usage() {
  echo "Usage: $0 [-g GENENAME] [-v VCF_FILE] [-c COVARS] [-p PHENO_LIST]"
  echo "  -g  Gene of interest (default: $GENENAME). Only relevant for unequivocal gene name convention."
  echo "  -v  Path to VCF file (default: $VCF_FILE)"
  echo "  -c  Comma-separated covariates (default: $COVARS)"
  echo "  -p  Space-separated phenotype list in quotes (default: ${PHENO_LIST[*]})"
  echo "Besides, by default, default PHENO_FILE is $PHENO_FILE, and OUTPUT_DIR is ${OUTPUT_DIR}."
}

while getopts 'g:c:p:h' flag; do
  case "${flag}" in
    g) GENENAME="${OPTARG}" ;;
    v) VCF_FILE="${OPTARG}" ;;
    c) COVARS="${OPTARG}" ;;
    p) IFS=' ' read -r -a PHENO_LIST <<< "${OPTARG}" ;;
    h) print_usage; exit 0 ;;
    *) print_usage; exit 1 ;;
  esac
done
# ========== FOLDER INIT================

mkdir -p "$OUTPUT_DIR/${GENENAME}"

# ========== MAIN LOOP =================
AGG_LOG="$OUTPUT_DIR/${GENENAME}/GENERAL_${GENENAME}_$(date +%F).log"
for PHENO in "${PHENO_LIST[@]}"; do
  echo "Running GWAS for phenotype: {$PHENO}, with Covars: {$COVARS}, and Gene: {$GENENAME}"

  plink2 \
    --double-id \
    --vcf "$VCF_FILE" dosage=HDS \
    --pheno "$PHENO_FILE" \
    --pheno-name "$PHENO" \
    --covar "$PHENO_FILE" \
    --covar-name $COVARS \
    --glm hide-covar \
    --out "$OUTPUT_DIR/${GENENAME}/${GENENAME}_${PHENO}_$(date +%F)"

  #### print in log file.
  echo "🔬 PHENOTYPE: $PHENO" >> "$AGG_LOG"
  echo "==============================================" >> "$AGG_LOG"
  find "$OUTPUT_DIR/${GENENAME}/" -name "${GENENAME}_${PHENO}_$(date +%F)*.log" -print0 | \
  tee >(xargs -0 cat >> "$AGG_LOG") | \
  xargs -0 rm -f # clean log file pheno-specific
  echo -e "\n\n" >> "$AGG_LOG"

  echo "Finished GWAS for phenotype: $PHENO"
  echo ""
done


