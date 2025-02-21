# CARTaGENE-GWAS

Analyse biological interactions between histocompatibility genes (HDAC) and HLA genes with ... disease in CARTaGENE.

## Pipeline

### Genome sequencing and mappig

The Cartagène project collects around 1000 RNA-Seq and 198 exomes (against 43,000 participants recruited in total), that were processed with [`Dragen Illumina`](https://www.nature.com/articles/s41587-024-02382-1), 
with the associated file stored in `/mnt/scratch_tn04/cartagene/Cartagen.vcf.gz`^[The correspondence for 111-coded samples is in the main file with 142333 codes.]

### Exome extraction

**Next steps**: extract exome data from the VCF and analyze RNA-Seq files using [`isovar`](https://github.com/openvax/isovar).