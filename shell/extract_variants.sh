#!/bin/bash

# === Default settings ===
CSV_FILE="./data/gene_positions/hdac_coords.csv"  # replace with your actual CSV path
VCF_DIR="./data/genotypages"
OUT_DIR="./data/variants"
MAF_CUTOFF="0.01"

# Ensure output directory exists
mkdir -p "$OUT_DIR"

# === Read and process the CSV ===
tail -n +2 "$CSV_FILE" | awk -F',' '{print $1, $3, $4, $5}' | while read -r HGNC_SYMBOL TXCHROM TXSTART TXEND
do
    # Sanitize values (remove spaces, trim)
    HGNC_SYMBOL=$(echo "$HGNC_SYMBOL" | xargs)
    TXCHROM=$(echo "$TXCHROM" | xargs)
    TXSTART=$(echo "$TXSTART" | xargs)
    TXEND=$(echo "$TXEND" | xargs)

    # Find matching VCF file
    VCF_FILE=$(find "$VCF_DIR" -type f | grep -i "${TXCHROM}.*\.vcf\.gz" | head -n 1)
    echo "🔹 VCF File is: $VCF_FILE

    # Check if VCF was found
    if [[ -z "$VCF_FILE" ]]; then
        echo "⚠️  Skipping $HGNC_SYMBOL - VCF for $TXCHROM file not found."
        continue
    fi

    # Construct output path
    OUT_FILE="${OUT_DIR}/${TXCHROM}.${HGNC_SYMBOL}.vcf"

    # Construct command
    CMD="bcftools filter --regions ${TXCHROM}:${TXSTART}-${TXEND} --include 'MAF[0] > ${MAF_CUTOFF}' \"$VCF_FILE\" -o \"$OUT_FILE\""

    # Echo metadata and command
    echo "🔹 Processing: $HGNC_SYMBOL | $TXCHROM:$TXSTART-$TXEND"
    echo "🔧 Command: $CMD"
    echo "---------------------------------------------"

    # Run the command
    # eval "$CMD"

done
