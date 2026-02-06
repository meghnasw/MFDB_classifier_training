# Add more BioProjects to the MFDB dataset

This page describes how to add additional NCBI BioProjects (PRJNA / PRJEB / PRJDB / etc.) to the MFDB pipeline, including primer removal, QC, denoising, OTU clustering, and merging results into a combined OTU table and metadata.

---

## What you need before starting

### A) BioProject IDs file
Create a plain text file named:

- All_bioproject.txt

Format (one BioProject ID per line). A header of `id` is needed.

    id
    PRJDB14548
    PRJEB30836

### B) Primer pairs file is needed
Create a plain text file named:

- primers.txt

Format (tab- or space-separated; first two columns are forward and reverse). Example:

    FWD    REV
    ACTGAGAYACGGYCCA    CTGCTGGCACGDAGTTAGCC
    GTGTGCCAGCMGCCGCGGTAA    GGACTACHVGGGTWTCTAAT

Multiple rows = multiple primer pairs; the script will try all provided primers. If no primers match the sequences, primer removal is skipped.

### C) Required software
- QIIME2 (qiime2-amplicon-2024.10)
- qiime fondue
- qiime cutadapt
- FastQC + MultiQC
- qiime dada2
- qiime vsearch

### D) Reference file for closed-reference OTU clustering
The script expects (relative to each BioProject folder):

    ../ref_file/silva-138-ssu-nr99-seqs-derep-uniq-97.qza

This SILVA 97% reference artifact is available in the prediction workflow repository under `Reference_files/`:

- <https://github.com/meghnasw/Predict-mock-samples-forensic-BFID/tree/main/Reference_files>

---

## Run the BioProject processing script

Save the following as: add_bioprojects.sh (in the folder containing All_bioproject.txt and primers.txt), then run it.

Note: This script uses `set -uo pipefail` (no `-e`) so it continues even if one BioProject fails.

SCRIPT: add_bioprojects.sh

    #!/usr/bin/env bash
    set -uo pipefail   # no -e so we don't exit on first error

    INPUT_FILE="All_bioproject.txt"
    PRIMERS_FILE="primers.txt"

    # Arrays for multiple primers
    FWD_PRIMERS=()
    REV_PRIMERS=()

    # Read primers if file exists
    if [ -f "$PRIMERS_FILE" ]; then
        echo "Found $PRIMERS_FILE, reading primer pairs..."

        while read -r FWD REV _; do
            # Clean whitespace/CR
            FWD=$(echo "$FWD" | tr -d '\r' | xargs)
            REV=$(echo "$REV" | tr -d '\r' | xargs)

            # Skip empty lines
            [ -z "$FWD" ] && [ -z "$REV" ] && continue

            # Skip header lines
            case "$FWD" in
                FWD|FORWARD|Forward|forward) continue ;;
            esac

            if [ -n "$FWD" ]; then
                FWD_PRIMERS+=("$FWD")
            fi
            if [ -n "$REV" ]; then
                REV_PRIMERS+=("$REV")
            fi
        done < "$PRIMERS_FILE"

        echo "Forward primers loaded: ${FWD_PRIMERS[*]:-<none>}"
        echo "Reverse primers loaded: ${REV_PRIMERS[*]:-<none>}"
    else
        echo "No $PRIMERS_FILE found. Primer removal will be skipped."
    fi

    echo
    echo "=== Starting processing of all BioProjects listed in $INPUT_FILE ==="

    while read -r BIOPROJ; do
        # Trim whitespace and CR
        BIOPROJ=$(echo "$BIOPROJ" | tr -d '\r' | xargs)

        # Skip empty lines and header
        if [ -z "$BIOPROJ" ] || [ "$BIOPROJ" = "id" ] || [ "$BIOPROJ" = "ID" ]; then
            continue
        fi

        echo
        echo "=============================================="
        echo "Processing BioProject: $BIOPROJ"
        echo "=============================================="

        mkdir -p "$BIOPROJ"
        cd "$BIOPROJ" || { echo "✗ Could not cd into $BIOPROJ, skipping."; cd ..; continue; }

        # --- IMPORT + FONDUE BLOCK ---
        if
            echo "→ Writing accession_ids.tsv for $BIOPROJ" &&
            {
                echo "ID"
                echo "$BIOPROJ"
            } > accession_ids.tsv &&

            echo "→ Importing accession IDs into QIIME artifact..." &&
            qiime tools import \
              --type NCBIAccessionIDs \
              --input-path accession_ids.tsv \
              --output-path "${BIOPROJ}.qza" &&
            echo "✓ Import complete." &&

            echo "→ Running qiime fondue get-sequences..." &&
            qiime fondue get-sequences \
              --i-accession-ids "${BIOPROJ}.qza" \
              --p-email meghnasw.96@gmail.com \
              --o-single-reads "${BIOPROJ}_single.qza" \
              --o-paired-reads "${BIOPROJ}_paired.qza" \
              --o-failed-runs "${BIOPROJ}_failed.qza" &&
            echo "✓ Fondue sequence retrieval complete."
        then
            :
        else
            echo "BioProject FAILED (fondue/import step): $BIOPROJ"
            cd ..
            continue
        fi

        # Start with the fondue output as input
        INPUT_PAIRED="${BIOPROJ}_paired.qza"

        # --- PRIMER REMOVAL WITH CUTADAPT (MULTIPLE PRIMERS) ---
        if [ "${#FWD_PRIMERS[@]}" -gt 0 ] || [ "${#REV_PRIMERS[@]}" -gt 0 ]; then
            echo "→ Removing primers with qiime cutadapt trim-paired (multiple primers)..."

            CUTADAPT_CMD=(qiime cutadapt trim-paired
                --i-demultiplexed-sequences "$INPUT_PAIRED"
                --o-trimmed-sequences "${BIOPROJ}_paired_trimmed.qza"
            )

            # Add all forward primers
            for P in "${FWD_PRIMERS[@]}"; do
                CUTADAPT_CMD+=(--p-front-f "$P")
            done

            # Add all reverse primers
            for P in "${REV_PRIMERS[@]}"; do
                CUTADAPT_CMD+=(--p-front-r "$P")
            done

            "${CUTADAPT_CMD[@]}" || {
                echo "Primer removal failed for $BIOPROJ"
                cd ..
                continue
            }

            echo "✓ Primer removal complete."
            INPUT_PAIRED="${BIOPROJ}_paired_trimmed.qza"
        else
            echo "→ No primers defined, skipping primer removal for $BIOPROJ."
        fi

        FASTQC_DIR="fastqc_reports"
        EXPORTED_DIR="exported_fastq"

        # --- DOWNSTREAM BLOCK (export, FastQC, MultiQC, DADA2, VSEARCH) ---
        if
            echo "→ Creating output folders: $FASTQC_DIR, $EXPORTED_DIR" &&
            mkdir -p "$FASTQC_DIR" "$EXPORTED_DIR" &&

            echo "→ Exporting FASTQ files from: $INPUT_PAIRED" &&
            sample_dir="$EXPORTED_DIR/${INPUT_PAIRED%.qza}" &&
            mkdir -p "$sample_dir" &&
            qiime tools export --input-path "$INPUT_PAIRED" --output-path "$sample_dir" &&
            echo "✓ FASTQ export complete." &&

            echo "→ Running FastQC..." &&
            fastqc $(find "$EXPORTED_DIR" -type f -name "*.fastq*") -o "$FASTQC_DIR" &&
            echo "✓ FastQC complete." &&

            echo "→ Running MultiQC..." &&
            multiqc "$FASTQC_DIR" -o "$FASTQC_DIR" &&
            echo "✓ MultiQC report generated." &&

            echo "→ Running DADA2 denoising on $INPUT_PAIRED..." &&
            qiime dada2 denoise-paired \
              --i-demultiplexed-seqs "$INPUT_PAIRED" \
              --p-trunc-len-f 0 --p-trunc-len-r 0 --p-n-threads 28 \
              --o-table "${BIOPROJ}_table.qza" \
              --o-representative-sequences "${BIOPROJ}_representative-sequences.qza" \
              --o-denoising-stats "${BIOPROJ}_denoising_stats.qza" \
              --verbose &&
            echo "✓ DADA2 denoising complete." &&

            echo "→ Running VSEARCH closed-reference clustering..." &&
            qiime vsearch cluster-features-closed-reference \
              --i-table "${BIOPROJ}_table.qza" \
              --i-sequences "${BIOPROJ}_representative-sequences.qza" \
              --i-reference-sequences ../ref_file/silva-138-ssu-nr99-seqs-derep-uniq-97.qza \
              --p-perc-identity 0.97 \
              --p-threads 28 \
              --o-clustered-table "${BIOPROJ}_clustered_table.qza" \
              --o-clustered-sequences "${BIOPROJ}_clustered_sequences.qza" \
              --o-unmatched-sequences "${BIOPROJ}_unmatched_sequences.qza" \
              --verbose &&
            echo "✓ VSEARCH clustering complete."
        then
            echo "BioProject COMPLETED SUCCESSFULLY: $BIOPROJ"
        else
            echo "BioProject FAILED (downstream step): $BIOPROJ"
        fi

        cd ..
    done < "$INPUT_FILE"

    echo
    echo "=== ALL BIOPROJECTS PROCESSED (some may have failed; see messages above) ==="

Create + run:

    chmod +x add_bioprojects.sh
    bash add_bioprojects.sh

---

## If you add multiple BioProjects: merge tables and metadata

This section is intentionally generic: replace folder/file names to match your setup.

### A) Merge OTU/feature tables

Example: merge all per-project clustered tables found in a folder:

    qiime feature-table merge \
      --i-tables <TABLES_FOLDER>/*.qza \
      --p-overlap-method sum \
      --o-merged-table merged_otu_table.qza

### B) Merge metadata files

Example: merge two metadata files:

    qiime metadata merge \
      --m-metadata1-file metadata_1.tsv \
      --m-metadata2-file metadata_2.tsv \
      --o-merged-metadata merged_metadata

Important metadata notes:
- The first metadata column should be named id
- Remove/rename duplicate column names before merging

### C) Optional filtering examples

Filter to keep only samples matching a condition (edit to your variables):

    qiime feature-table filter-samples \
      --i-table merged_otu_table.qza \
      --m-metadata-file merged_metadata.qza \
      --p-where '(Healthy IN ("yes","control")) AND (ITS = "no")' \
      --o-filtered-table merged_otu_table_filtered.qza

Filter out control samples:

    qiime feature-table filter-samples \
      --i-table merged_otu_table_filtered.qza \
      --m-metadata-file merged_metadata.tsv \
      --p-where "[Body_Site_Ed]='control'" \
      --p-exclude-ids \
      --o-filtered-table merged_otu_table_no_controls.qza

Filter OTUs observed in at least 2 samples:

    qiime feature-table filter-features \
      --i-table merged_otu_table_no_controls.qza \
      --p-min-samples 2 \
      --o-filtered-table merged_otu_table_no_controls_min2.qza

Remove samples with fewer than 1000 total reads (recommended):

    qiime feature-table filter-samples \
      --i-table merged_otu_table_no_controls_min2.qza \
      --p-min-frequency 1000 \
      --o-filtered-table merged_otu_table_no_controls_min2_min1000.qza

---

## Normalize (TSS) and convert back to FeatureTable[Frequency]

Create relative-frequency (TSS) table:

    qiime feature-table relative-frequency \
      --i-table merged_otu_table_no_controls_min2_min1000.qza \
      --o-relative-frequency-table merged_otu_table_tss.qza

Important: relative-frequency outputs FeatureTable[RelativeFrequency], but classifier training expects FeatureTable[Frequency].
To convert:
1) unzip the .qza
2) locate data/feature-table.biom
3) re-import as FeatureTable[Frequency]

Example re-import:

    qiime tools import \
      --input-path <UNZIPPED_QZA_DIR>/data/feature-table.biom \
      --type 'FeatureTable[Frequency]' \
      --input-format BIOMV210Format \
      --output-path otu_table.qza

---

## Train the classifier

Use the same `qiime sample-classifier classify-samples` command described in the [Training page](training.md), using your new table and metadata.
