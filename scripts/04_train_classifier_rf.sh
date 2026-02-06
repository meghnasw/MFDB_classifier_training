#!/usr/bin/env bash
set -euo pipefail

# Usage example:
# bash scripts/04_train_classifier_rf.sh filtered-table.qza metadata.tsv Body_Site_Ed my_custom_rf

TABLE="${1:?Provide filtered table .qza}"
META="${2:?Provide metadata file}"
TARGET_COL="${3:-Body_Site_Ed}"
OUTDIR="${4:-rf_classifier_run}"

qiime sample-classifier classify-samples \
  --i-table "$TABLE" \
  --m-metadata-file "$META" \
  --m-metadata-column "$TARGET_COL" \
  --p-optimize-feature-selection \
  --p-estimator RandomForestClassifier \
  --p-parameter-tuning \
  --p-n-jobs 8 \
  --p-n-estimators 500 \
  --p-random-state 123 \
  --output-dir "$OUTDIR"
