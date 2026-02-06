#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash scripts/06_summarize_training_outputs.sh rf_opt_classifier_tuning_seed123_n500
# or:
#   bash scripts/06_summarize_training_outputs.sh outputs/custom_classifier

OUTDIR="${1:?Provide the QIIME2 classify-samples output directory}"

qiime metadata tabulate \
  --m-input-file "${OUTDIR}/feature_importance.qza" \
  --o-visualization "${OUTDIR}/feature_importance.qzv"

qiime metadata tabulate \
  --m-input-file "${OUTDIR}/predictions.qza" \
  --o-visualization "${OUTDIR}/predictions.qzv"

qiime metadata tabulate \
  --m-input-file "${OUTDIR}/probabilities.qza" \
  --o-visualization "${OUTDIR}/probabilities.qzv"

qiime metadata tabulate \
  --m-input-file "${OUTDIR}/test_targets.qza" \
  --m-input-file "${OUTDIR}/predictions.qza" \
  --o-visualization "${OUTDIR}/test_targets_predictions.qzv"

echo "Done. Visualizations written to: ${OUTDIR}"
