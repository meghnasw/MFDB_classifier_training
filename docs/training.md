# Train your own classifier

## What users should set / edit

### A) Input files (paths)
- Feature/OTU table (`.qza`), e.g. `otu_Table_allsamples.qza`
- Metadata file (e.g. `.txt`), e.g. `metadata_final_withZIFMsamples.txt`

### B) Metadata column to predict
- `--m-metadata-column Body_Site_Ed`
  - Change `Body_Site_Ed` to the label column you want to predict (must exist in metadata).

### C) Sample filtering choice (body site / subset)
Users should set the WHERE clause, e.g.

    '[Body_Site_Ed] IN ("skin_hand", "skin_penile")'

### D) Output directory name
- `--output-dir <NAME>`
  - Use an informative name, e.g. `rf_skin_seed123`.

### E) Training parameters (optional)
- `--p-n-estimators 500`
- `--p-n-jobs 8`
- `--p-random-state 123`
- Keep or remove:
  - `--p-optimize-feature-selection`
  - `--p-parameter-tuning`

---

## Step 1 — Filter the OTU/feature table (example: skin)

    qiime feature-table filter-samples \
      --i-table otu_Table_allsamples.qza \
      --m-metadata-file metadata_final_withZIFMsamples.txt \
      --p-where '[Body_Site_Ed] IN ("skin_hand", "skin_penile")' \
      --o-filtered-table filtered-table.qza

---

## Step 2 — Train a classifier on the filtered table

This trains a supervised classifier using QIIME2’s `sample-classifier` plugin.
It trains a Random Forest model to predict `Body_Site_Ed` from the filtered feature table.
Feature selection + parameter tuning are enabled.

    qiime sample-classifier classify-samples \
      --i-table filtered-table.qza \
      --m-metadata-file metadata_final_withZIFMsamples.txt \
      --m-metadata-column Body_Site_Ed \
      --p-optimize-feature-selection \
      --p-estimator RandomForestClassifier \
      --p-parameter-tuning \
      --p-n-jobs 8 \
      --p-n-estimators 500 \
      --p-random-state 123 \
      --output-dir my_custom_rf
