# Create QIIME2 visualizations for training outputs (.qzv)

After training (e.g., output dir `my_custom_rf`), create these visualizations:

## Feature importance

    qiime metadata tabulate \
      --m-input-file my_custom_rf/feature_importance.qza \
      --o-visualization my_custom_rf/feature_importance.qzv

## Predictions

    qiime metadata tabulate \
      --m-input-file my_custom_rf/predictions.qza \
      --o-visualization my_custom_rf/predictions.qzv

## Probabilities

    qiime metadata tabulate \
      --m-input-file my_custom_rf/probabilities.qza \
      --o-visualization my_custom_rf/probabilities.qzv

## Test targets + predictions

    qiime metadata tabulate \
      --m-input-file my_custom_rf/test_targets.qza \
      --m-input-file my_custom_rf/predictions.qza \
      --o-visualization my_custom_rf/test_targets_predictions.qzv

Tip: if your output directory has a different name, replace `my_custom_rf/` in the commands.

To view `.qzv` files:
- https://view.qiime2.org
- or locally: `qiime tools view <file.qzv>`
